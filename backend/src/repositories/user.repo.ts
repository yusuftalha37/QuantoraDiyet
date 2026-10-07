import { query } from '../db/pool.js';

export interface UserRow {
  id: string;
  email: string;
  password_hash: string;
  display_name: string;
  is_active: boolean;
  failed_logins: number;
  locked_until: Date | null;
}

export async function findUserByEmail(email: string): Promise<UserRow | null> {
  const r = await query<UserRow>(
    `SELECT id, email, password_hash, display_name, is_active, failed_logins, locked_until
       FROM users WHERE lower(email) = lower($1) LIMIT 1`,
    [email],
  );
  return r.rows[0] ?? null;
}

export async function findUserById(id: string): Promise<UserRow | null> {
  const r = await query<UserRow>(
    `SELECT id, email, password_hash, display_name, is_active, failed_logins, locked_until
       FROM users WHERE id = $1 LIMIT 1`,
    [id],
  );
  return r.rows[0] ?? null;
}

export async function createUser(
  email: string,
  passwordHash: string,
  displayName: string,
): Promise<UserRow> {
  const r = await query<UserRow>(
    `INSERT INTO users (email, password_hash, display_name)
       VALUES ($1, $2, $3)
     RETURNING id, email, password_hash, display_name, is_active, failed_logins, locked_until`,
    [email, passwordHash, displayName],
  );
  return r.rows[0]!;
}

export async function recordFailedLogin(userId: string, lockThreshold = 5, lockMinutes = 15): Promise<void> {
  // Lock the account temporarily after repeated failures (brute-force defence).
  await query(
    `UPDATE users
        SET failed_logins = failed_logins + 1,
            locked_until = CASE WHEN failed_logins + 1 >= $2
                                THEN now() + ($3 || ' minutes')::interval
                                ELSE locked_until END,
            updated_at = now()
      WHERE id = $1`,
    [userId, lockThreshold, String(lockMinutes)],
  );
}

export async function resetFailedLogins(userId: string): Promise<void> {
  await query(
    `UPDATE users SET failed_logins = 0, locked_until = NULL, updated_at = now() WHERE id = $1`,
    [userId],
  );
}

export async function updatePassword(userId: string, passwordHash: string): Promise<void> {
  await query(`UPDATE users SET password_hash = $2, updated_at = now() WHERE id = $1`, [
    userId,
    passwordHash,
  ]);
}

/** Kullanıcıyı ve (cascade ile) profil/pantry/plan/token'larını siler. */
export async function deleteUser(userId: string): Promise<void> {
  await query(`DELETE FROM users WHERE id = $1`, [userId]);
}
