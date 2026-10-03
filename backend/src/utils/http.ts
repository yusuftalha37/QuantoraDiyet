import type { NextFunction, Request, Response, RequestHandler } from 'express';

/**
 * Wraps an async route handler so rejected promises reach the Express error
 * middleware instead of crashing the process as unhandled rejections.
 */
export function asyncHandler(
  fn: (req: Request, res: Response, next: NextFunction) => Promise<unknown>,
): RequestHandler {
  return (req, res, next) => {
    fn(req, res, next).catch(next);
  };
}
