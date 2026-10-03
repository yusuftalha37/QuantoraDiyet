import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';

export interface AccessClaims {
  sub: string; // user id
  email: string;
  type: 'access';
}

/** Short-lived access token (stateless, verified by signature). */
export function signAccessToken(userId: string, email: string): string {
  const payload: AccessClaims = { sub: userId, email, type: 'access' };
  return jwt.sign(payload, env.JWT_ACCESS_SECRET, {
    expiresIn: env.JWT_ACCESS_TTL,
    issuer: 'quantoradiyet',
    audience: 'quantoradiyet-app',
  });
}

export function verifyAccessToken(token: string): AccessClaims {
  const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET, {
    issuer: 'quantoradiyet',
    audience: 'quantoradiyet-app',
  }) as jwt.JwtPayload;
  if (decoded.type !== 'access' || typeof decoded.sub !== 'string') {
    throw new Error('Invalid token type');
  }
  return { sub: decoded.sub, email: String(decoded.email), type: 'access' };
}

/**
 * Refresh tokens are long, high-entropy opaque strings. We store ONLY their
 * SHA-256 hash in the DB, so a database leak cannot be used to mint sessions.
 */
export function generateRefreshToken(): { token: string; hash: string } {
  const token = crypto.randomBytes(48).toString('base64url');
  const hash = hashRefreshToken(token);
  return { token, hash };
}

export function hashRefreshToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export function refreshExpiryDate(): Date {
  return new Date(Date.now() + env.JWT_REFRESH_TTL * 1000);
}
