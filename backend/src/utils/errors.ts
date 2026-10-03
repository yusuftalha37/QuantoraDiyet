/**
 * Operational error carrying an HTTP status and a safe, client-facing code.
 * Anything thrown that is NOT an AppError is treated as an unexpected 500 and
 * its details are never sent to the client.
 */
export class AppError extends Error {
  readonly status: number;
  readonly code: string;
  readonly details?: unknown;

  constructor(status: number, code: string, message: string, details?: unknown) {
    super(message);
    this.name = 'AppError';
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export const badRequest = (msg: string, details?: unknown) =>
  new AppError(400, 'BAD_REQUEST', msg, details);
export const unauthorized = (msg = 'Kimlik doğrulaması gerekli') =>
  new AppError(401, 'UNAUTHORIZED', msg);
export const forbidden = (msg = 'Bu işleme yetkiniz yok') =>
  new AppError(403, 'FORBIDDEN', msg);
export const notFound = (msg = 'Kayıt bulunamadı') =>
  new AppError(404, 'NOT_FOUND', msg);
export const conflict = (msg: string) => new AppError(409, 'CONFLICT', msg);
export const tooMany = (msg = 'Çok fazla istek') =>
  new AppError(429, 'TOO_MANY_REQUESTS', msg);
