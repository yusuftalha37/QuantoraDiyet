import pino from 'pino';
import { env } from './env.js';

/**
 * Structured logger. Redacts anything that could leak credentials or tokens,
 * so logs are safe to ship to aggregation without exposing secrets.
 */
export const logger = pino({
  level: env.isProd ? 'info' : 'debug',
  redact: {
    paths: [
      'req.headers.authorization',
      'req.headers.cookie',
      'req.body.password',
      'req.body.currentPassword',
      'req.body.newPassword',
      'req.body.refreshToken',
      'res.headers["set-cookie"]',
      '*.password',
      '*.token',
      '*.refreshToken',
      '*.accessToken',
    ],
    censor: '[REDACTED]',
  },
  transport: env.isProd
    ? undefined
    : { target: 'pino-pretty', options: { colorize: true, translateTime: 'HH:MM:ss' } },
});
