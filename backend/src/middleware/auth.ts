import type { NextFunction, Request, Response } from 'express';
import { verifyAccessToken } from '../services/tokens.js';
import { unauthorized } from '../utils/errors.js';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      auth?: { userId: string; email: string };
    }
  }
}

/**
 * Requires a valid Bearer access token. Populates `req.auth`.
 * Any verification failure (expired, tampered, wrong type) → 401, with no
 * detail about which check failed.
 */
export function requireAuth(req: Request, _res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    next(unauthorized());
    return;
  }
  const token = header.slice('Bearer '.length).trim();
  try {
    const claims = verifyAccessToken(token);
    req.auth = { userId: claims.sub, email: claims.email };
    next();
  } catch {
    next(unauthorized('Geçersiz veya süresi dolmuş oturum'));
  }
}
