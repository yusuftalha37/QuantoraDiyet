import { env } from '../config/env.js';
import { unauthorized } from '../utils/errors.js';

export interface GoogleIdentity {
  sub: string;
  email: string;
  name?: string;
}

/**
 * Google ID token'ı Google'ın tokeninfo uç noktasıyla doğrular (ek bağımlılık
 * gerektirmeden). Audience (client id), issuer ve e-posta doğrulamasını kontrol
 * eder; geçersizse 401 atar.
 */
export async function verifyGoogleIdToken(idToken: string): Promise<GoogleIdentity> {
  if (env.googleClientIds.length === 0) {
    throw unauthorized('Google girişi sunucuda yapılandırılmamış');
  }
  const res = await fetch(
    'https://oauth2.googleapis.com/tokeninfo?id_token=' + encodeURIComponent(idToken),
  );
  if (!res.ok) throw unauthorized('Google kimliği doğrulanamadı');

  const p = (await res.json()) as Record<string, unknown>;
  const iss = String(p.iss ?? '');
  if (iss !== 'accounts.google.com' && iss !== 'https://accounts.google.com') {
    throw unauthorized('Geçersiz Google token (issuer)');
  }
  if (!env.googleClientIds.includes(String(p.aud ?? ''))) {
    throw unauthorized('Google istemci kimliği eşleşmedi');
  }
  const emailVerified = p.email_verified === true || p.email_verified === 'true';
  if (!emailVerified) throw unauthorized('Google e-postası doğrulanmamış');
  if (!p.email || !p.sub) throw unauthorized('Google token eksik bilgi içeriyor');

  return {
    sub: String(p.sub),
    email: String(p.email).toLowerCase(),
    name: typeof p.name === 'string' ? p.name : undefined,
  };
}
