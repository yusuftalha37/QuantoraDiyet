import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { pool } from './pool.js';
import { logger } from '../config/logger.js';

/**
 * Minimal forward-only migration runner. Applies every *.sql file in
 * `migrations/` in lexical order exactly once, tracked in schema_migrations.
 */
const here = dirname(fileURLToPath(import.meta.url));
const migrationsDir = join(here, 'migrations');

async function run(): Promise<void> {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      name       TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
  `);

  const files = readdirSync(migrationsDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  for (const file of files) {
    const already = await pool.query('SELECT 1 FROM schema_migrations WHERE name = $1', [file]);
    if ((already.rowCount ?? 0) > 0) {
      logger.info({ file }, 'migration already applied, skipping');
      continue;
    }
    const sql = readFileSync(join(migrationsDir, file), 'utf8');
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(sql);
      await client.query('INSERT INTO schema_migrations (name) VALUES ($1)', [file]);
      await client.query('COMMIT');
      logger.info({ file }, 'migration applied');
    } catch (err) {
      await client.query('ROLLBACK');
      logger.error({ file, err }, 'migration failed');
      throw err;
    } finally {
      client.release();
    }
  }
}

run()
  .then(() => pool.end())
  .then(() => {
    logger.info('migrations complete');
    process.exit(0);
  })
  .catch((err) => {
    logger.error({ err }, 'migration runner crashed');
    process.exit(1);
  });
