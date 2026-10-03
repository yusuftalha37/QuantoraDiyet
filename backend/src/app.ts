import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import pinoHttp from 'pino-http';
import { env } from './config/env.js';
import { logger } from './config/logger.js';
import { globalLimiter } from './middleware/rateLimit.js';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js';
import { apiRouter } from './routes/index.js';

export function createApp() {
  const app = express();

  // Behind a reverse proxy / load balancer in production (correct client IPs
  // for rate limiting and secure-cookie detection).
  app.set('trust proxy', env.isProd ? 1 : false);
  app.disable('x-powered-by');

  // Security headers. This is a JSON API, so a strict, locked-down CSP is fine.
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: { defaultSrc: ["'none'"], frameAncestors: ["'none'"] },
      },
      crossOriginResourcePolicy: { policy: 'same-site' },
      referrerPolicy: { policy: 'no-referrer' },
      hsts: env.isProd ? { maxAge: 31_536_000, includeSubDomains: true, preload: true } : false,
    }),
  );

  // Strict CORS: only explicitly allowlisted origins; requests with no Origin
  // (native mobile apps, curl) are allowed through for the API.
  app.use(
    cors({
      origin(origin, cb) {
        if (!origin || env.corsOrigins.includes(origin)) return cb(null, true);
        return cb(new Error('CORS: origin not allowed'));
      },
      credentials: true,
      methods: ['GET', 'POST', 'PATCH', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      maxAge: 600,
    }),
  );

  // Body size caps mitigate memory-exhaustion DoS via huge payloads.
  app.use(express.json({ limit: '64kb' }));
  app.use(cookieParser());
  app.use(pinoHttp({ logger }));
  app.use(globalLimiter);

  app.get('/health', (_req, res) => res.json({ status: 'ok', ts: new Date().toISOString() }));
  app.use('/api/v1', apiRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
