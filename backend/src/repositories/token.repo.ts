import { query, withTransaction } from '../db/pool.js';

export interface RefreshRow {
  id: string;
  user_id: string;
  token_hash: string;
  expires_at: Date;
  revoked_at: Date | null;
  replaced_by: string | null;
}

export async function storeRefreshToken(
  userId: string,
  tokenHash: string,
  expiresAt: Date,
  userAgent: string | null,
): Promise<string> {
  const r = await query<{ id: string }>(
    `INSERT INTO refresh_tokens (user_id, token_hash, expires_at, user_agent)
       VALUES ($1, $2, $3, $4) RETURNING id`,
    [userId, tokenHash, expiresAt, userAgent],
  );
  return r.rows[0]!.id;
}

export async function findRefreshByHash(tokenHash: string): Promise<RefreshRow | null> {
  const r = await query<RefreshRow>(
    `SELECT id, user_id, token_hash, expires_at, revoked_at, replaced_by
       FROM refresh_tokens WHERE token_hash = $1 LIMIT 1`,
    [tokenHash],
  );
  return r.rows[0] ?? null;
}

/**
 * Rotate a refresh token: revoke the old one and store the new, atomically.
 * If the presented token was already revoked, the caller treats it as reuse
 * (possible theft) and revokes the whole family.
 */
export async function rotateRefreshToken(
  oldId: string,
  userId: string,
  newHash: string,
  expiresAt: Date,
  userAgent: string | null,
): Promise<string> {
  return withTransaction(async (client) => {
    const ins = await client.query<{ id: string }>(
      `INSERT INTO refresh_tokens (user_id, token_hash, expires_at, user_agent)
         VALUES ($1, $2, $3, $4) RETURNING id`,
      [userId, newHash, expiresAt, userAgent],
    );
    const newId = ins.rows[0]!.id;
    await client.query(
      `UPDATE refresh_tokens SET revoked_at = now(), replaced_by = $2 WHERE id = $1`,
      [oldId, newId],
    );
    return newId;
  });
}

export async function revokeToken(id: string): Promise<void> {
  await query(`UPDATE refresh_tokens SET revoked_at = now() WHERE id = $1 AND revoked_at IS NULL`, [id]);
}

/** Revoke every active token for a user (logout everywhere / suspected theft). */
export async function revokeAllForUser(userId: string): Promise<void> {
  await query(`UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL`, [
    userId,
  ]);
}
