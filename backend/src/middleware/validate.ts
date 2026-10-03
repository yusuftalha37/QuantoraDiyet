import type { NextFunction, Request, Response } from 'express';
import { ZodError, type ZodTypeAny } from 'zod';
import { badRequest } from '../utils/errors.js';

type Part = 'body' | 'query' | 'params';

/**
 * Validates and REPLACES the given request part with the parsed, typed value.
 * Unknown keys are stripped by the schema (zod `.strict()`/default strip),
 * so handlers only ever see data that passed validation.
 */
export function validate<S extends ZodTypeAny>(schema: S, part: Part = 'body') {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req[part]);
    if (!result.success) {
      const err = result.error as ZodError;
      next(
        badRequest(
          'Girdi doğrulaması başarısız',
          err.issues.map((i) => ({ path: i.path.join('.'), message: i.message })),
        ),
      );
      return;
    }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    (req as any)[part] = result.data;
    next();
  };
}
