import { createApp } from './app.js';
import { env } from './config/env.js';
import { logger } from './config/logger.js';
import { closePool } from './db/pool.js';

const app = createApp();
const server = app.listen(env.PORT, () => {
  logger.info({ port: env.PORT, env: env.NODE_ENV }, 'QuantoraDiyet API listening');
});

async function shutdown(signal: string): Promise<void> {
  logger.info({ signal }, 'shutting down');
  server.close(async () => {
    await closePool();
    process.exit(0);
  });
  // Force-exit if graceful shutdown stalls.
  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on('SIGTERM', () => void shutdown('SIGTERM'));
process.on('SIGINT', () => void shutdown('SIGINT'));
