import type { NextFunction, Request, Response } from 'express';
import { AppError } from '../utils/errors.js';
import { logger } from '../config/logger.js';
import { env } from '../config/env.js';

/** 404 for unmatched routes. */
export function notFoundHandler(_req: Request, res: Response): void {
  res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Uç nokta bulunamadı' } });
}

/**
 * Central error handler. Operational AppErrors are returned with their safe
 * code/message. Everything else is logged in full server-side and returned to
 * the client as a generic 500 — internal details are never leaked.
 */
export function errorHandler(
  err: unknown,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _next: NextFunction,
): void {
  if (err instanceof AppError) {
    if (err.status >= 500) logger.error({ err, path: req.path }, 'operational 5xx');
    res.status(err.status).json({
      error: { code: err.code, message: err.message, details: err.details },
    });
    return;
  }

  logger.error({ err, path: req.path }, 'unhandled error');
  res.status(500).json({
    error: {
      code: 'INTERNAL',
      message: 'Beklenmeyen bir hata oluştu',
      ...(env.isProd ? {} : { debug: err instanceof Error ? err.message : String(err) }),
    },
  });
}
