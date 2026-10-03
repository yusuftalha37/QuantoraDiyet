import bcrypt from 'bcrypt';
import { env } from '../config/env.js';
import { conflict, unauthorized, forbidden } from '../utils/errors.js';
import {
  createUser,
  findUserByEmail,
  findUserById,
  recordFailedLogin,
  resetFailedLogins,
} from '../repositories/user.repo.js';
import {
  findRefreshByHash,
  rotateRefreshToken,
  revokeAllForUser,
  revokeToken,
  storeRefreshToken,
} from '../repositories/token.repo.js';
import {
  generateRefreshToken,
  hashRefreshToken,
  refreshExpiryDate,
  signAccessToken,
} from './tokens.js';

export interface AuthResult {
  user: { id: string; email: string; displayName: string };
  accessToken: string;
  refreshToken: string;
}

export async function register(
  email: string,
  password: string,
  displayName: string,
  userAgent: string | null,
): Promise<AuthResult> {
  const existing = await findUserByEmail(email);
  if (existing) {
    // Generic message — do not reveal whether an email is registered.
    throw conflict('Bu e-posta ile kayıt oluşturulamadı');
  }
  const passwordHash = await bcrypt.hash(password, env.BCRYPT_ROUNDS);
  const user = await createUser(email, passwordHash, displayName);
  return issueSession(user.id, user.email, user.display_name, userAgent);
}

export async function login(
  email: string,
  password: string,
  userAgent: string | null,
): Promise<AuthResult> {
  const user = await findUserByEmail(email);

  // Always run a bcrypt comparison to keep response timing uniform whether or
  // not the account exists (mitigates user-enumeration via timing).
  const hashToCompare = user?.password_hash ?? '$2b$12$usersdonotexist0000000000000000000000000000000000000000';
  const ok = await bcrypt.compare(password, hashToCompare);

  if (!user || !ok) {
    if (user) await recordFailedLogin(user.id);
    throw unauthorized('E-posta veya parola hatalı');
  }
  if (!user.is_active) throw forbidden('Hesap devre dışı');
  if (user.locked_until && user.locked_until.getTime() > Date.now()) {
    throw forbidden('Hesap geçici olarak kilitli, lütfen sonra tekrar deneyin');
  }

  await resetFailedLogins(user.id);
  return issueSession(user.id, user.email, user.display_name, userAgent);
}

export async function refresh(presentedToken: string, userAgent: string | null): Promise<AuthResult> {
  const hash = hashRefreshToken(presentedToken);
  const row = await findRefreshByHash(hash);
  if (!row) throw unauthorized('Oturum geçersiz');

  // Reuse of an already-revoked token signals theft → revoke the whole family.
  if (row.revoked_at) {
    await revokeAllForUser(row.user_id);
    throw unauthorized('Oturum yeniden kullanıldı, tüm oturumlar kapatıldı');
  }
  if (row.expires_at.getTime() <= Date.now()) {
    await revokeToken(row.id);
    throw unauthorized('Oturum süresi doldu');
  }

  const user = await findUserById(row.user_id);
  if (!user || !user.is_active) throw unauthorized('Kullanıcı bulunamadı');

  const { token: newToken, hash: newHash } = generateRefreshToken();
  await rotateRefreshToken(row.id, row.user_id, newHash, refreshExpiryDate(), userAgent);

  return {
    user: { id: user.id, email: user.email, displayName: user.display_name },
    accessToken: signAccessToken(user.id, user.email),
    refreshToken: newToken,
  };
}

export async function logout(presentedToken: string): Promise<void> {
  const row = await findRefreshByHash(hashRefreshToken(presentedToken));
  if (row && !row.revoked_at) await revokeToken(row.id);
}

export async function logoutEverywhere(userId: string): Promise<void> {
  await revokeAllForUser(userId);
}

// ---- helpers ----
async function issueSession(
  userId: string,
  email: string,
  displayName: string,
  userAgent: string | null,
): Promise<AuthResult> {
  const accessToken = signAccessToken(userId, email);
  const { token, hash } = generateRefreshToken();
  await storeRefreshToken(userId, hash, refreshExpiryDate(), userAgent);
  return { user: { id: userId, email, displayName }, accessToken, refreshToken: token };
}
