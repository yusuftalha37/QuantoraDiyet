import rateLimit from 'express-rate-limit';
import { env } from '../config/env.js';

/** Global per-IP limiter applied to the whole API. */
export const globalLimiter = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.RATE_LIMIT_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { code: 'TOO_MANY_REQUESTS', message: 'Çok fazla istek, lütfen sonra tekrar deneyin' } },
});

/** Stricter limiter for auth endpoints to slow brute-force / credential stuffing. */
export const authLimiter = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.AUTH_RATE_LIMIT_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  // Count only failed attempts so legitimate logins aren't penalised.
  skipSuccessfulRequests: true,
  message: { error: { code: 'TOO_MANY_REQUESTS', message: 'Çok fazla giriş denemesi, lütfen bekleyin' } },
});

/** AI generation is expensive; cap it per IP independently. */
export const aiLimiter = rateLimit({
  windowMs: 60_000,
  max: 12,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { code: 'TOO_MANY_REQUESTS', message: 'Plan üretimi için çok fazla istek' } },
});
