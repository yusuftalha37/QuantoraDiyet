import 'dotenv/config';
import { z } from 'zod';

/**
 * Centralised, validated environment configuration.
 * The process refuses to start if required secrets are missing or weak,
 * so misconfiguration fails fast instead of silently degrading security.
 */
const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(4000),
  CORS_ORIGINS: z.string().default(''),

  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),

  JWT_ACCESS_SECRET: z.string().min(32, 'JWT_ACCESS_SECRET must be >= 32 chars'),
  JWT_REFRESH_SECRET: z.string().min(32, 'JWT_REFRESH_SECRET must be >= 32 chars'),
  JWT_ACCESS_TTL: z.coerce.number().int().positive().default(900),
  JWT_REFRESH_TTL: z.coerce.number().int().positive().default(2_592_000),

  BCRYPT_ROUNDS: z.coerce.number().int().min(10).max(15).default(12),
  RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(900_000),
  RATE_LIMIT_MAX: z.coerce.number().int().positive().default(300),
  AUTH_RATE_LIMIT_MAX: z.coerce.number().int().positive().default(10),

  AI_PROVIDER: z.enum(['anthropic', 'none']).default('none'),
  ANTHROPIC_API_KEY: z.string().optional().default(''),
  AI_MODEL: z.string().default('claude-opus-4-8'),
  AI_MAX_TOKENS: z.coerce.number().int().positive().default(4096),
  AI_TIMEOUT_MS: z.coerce.number().int().positive().default(30_000),

  // Google ile giriş: kabul edilen OAuth client ID'leri (virgülle ayrılmış).
  // Boşsa Google girişi devre dışıdır.
  GOOGLE_CLIENT_IDS: z.string().optional().default(''),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  // eslint-disable-next-line no-console
  console.error('Invalid environment configuration:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

const raw = parsed.data;

// In production, the two JWT secrets must differ and must not be the placeholder.
if (raw.NODE_ENV === 'production') {
  if (raw.JWT_ACCESS_SECRET === raw.JWT_REFRESH_SECRET) {
    // eslint-disable-next-line no-console
    console.error('JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must differ in production');
    process.exit(1);
  }
  if (raw.AI_PROVIDER === 'anthropic' && !raw.ANTHROPIC_API_KEY) {
    // eslint-disable-next-line no-console
    console.error('AI_PROVIDER=anthropic but ANTHROPIC_API_KEY is empty');
    process.exit(1);
  }
}

export const env = {
  ...raw,
  isProd: raw.NODE_ENV === 'production',
  corsOrigins: raw.CORS_ORIGINS.split(',')
    .map((o) => o.trim())
    .filter(Boolean),
  googleClientIds: raw.GOOGLE_CLIENT_IDS.split(',')
    .map((o) => o.trim())
    .filter(Boolean),
};

export type Env = typeof env;
