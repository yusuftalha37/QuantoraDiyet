# Güvenlik Mimarisi

QuantoraDiyet'te güvenlik, uygulamanın ilk tasarımından itibaren katmanlı
olarak ele alınmıştır. Bu belge uygulanan kontrolleri özetler.

## 1. Kimlik doğrulama ve oturum yönetimi

- **Parola saklama:** Parolalar `bcrypt` (maliyet faktörü 12, yapılandırılabilir)
  ile hashlenir. Düz metin parola hiçbir yerde saklanmaz veya loglanmaz.
- **Parola politikası:** En az 10 karakter, büyük/küçük harf ve rakam zorunlu
  (`src/schemas.ts`), hem backend hem mobil tarafta doğrulanır.
- **JWT access token:** Kısa ömürlü (varsayılan 15 dk), imzalı, `issuer`/
  `audience` doğrulamalı. Durum tutmaz, sunucuda saklanmaz.
- **Refresh token:** Yüksek entropili rastgele değer; veritabanında yalnızca
  **SHA-256 hash'i** tutulur. Böylece DB sızıntısında oturumlar ele geçirilemez.
- **Refresh rotasyonu + yeniden kullanım tespiti:** Her yenilemede eski token
  iptal edilir, yenisi üretilir. İptal edilmiş bir token tekrar kullanılırsa
  (hırsızlık sinyali) kullanıcının tüm oturumları iptal edilir.
- **Kaba kuvvet koruması:** Art arda başarısız girişlerde hesap geçici olarak
  kilitlenir (`recordFailedLogin`). Giriş yanıtları, hesabın var olup olmadığını
  sızdırmaz; zamanlama saldırısına karşı her durumda bcrypt karşılaştırması yapılır.

## 2. Taşıma ve istemci güvenliği

- Mobil uygulamada **API anahtarı veya sır bulunmaz.** Tüm gizli anahtarlar
  (AI sağlayıcı anahtarı dâhil) yalnızca backend'de tutulur.
- Mobil tarafta token'lar `flutter_secure_storage` ile **platform şifreli**
  depoda (Android Keystore / EncryptedSharedPreferences) saklanır.
- Üretimde tüm trafik **HTTPS** üzerinden olmalıdır (HSTS etkin).

## 3. HTTP katmanı sertleştirmesi

- `helmet` ile güvenlik başlıkları; API için kilitli CSP (`default-src 'none'`).
- **Sıkı CORS:** Yalnızca `CORS_ORIGINS` listesindeki kaynaklar.
- **Rate limiting:** Global limit + auth uç noktalarına özel sıkı limit +
  AI üretimine özel limit (maliyet ve kötüye kullanım kontrolü).
- **Gövde boyutu limiti** (64 KB) ile bellek tüketimi/DoS azaltımı.
- `x-powered-by` kapalı; `trust proxy` üretimde doğru istemci IP'si için ayarlı.

## 4. Girdi doğrulama ve enjeksiyon savunması

- Tüm istek gövdeleri/parametreleri **zod** şemalarından geçer; bilinmeyen
  alanlar ayıklanır, sınırlar zorlanır.
- Veritabanı erişimi **yalnızca parametreli sorgularla** yapılır
  (`$1, $2 ...`); dize birleştirmeli SQL yoktur → SQL injection'a kapalı.
- AI (LLM) çıktısı **güvenilmez** kabul edilir: şemaya göre katı doğrulanır,
  geçersizse reddedilip deterministik motora düşülür.

## 5. Hata yönetimi ve loglama

- Merkezî hata yöneticisi; operasyonel hatalar güvenli kod/mesajla döner,
  beklenmeyen hatalar sunucuda loglanır ve istemciye **genel 500** döner
  (yığın izi/iç detay sızmaz).
- `pino` loglarında Authorization, cookie, parola ve token alanları **redakte**
  edilir.

## 6. Veri modeli

- Kullanıcı silindiğinde profili, pantry'si, planları ve token'ları
  `ON DELETE CASCADE` ile birlikte silinir.
- E-posta büyük/küçük harf duyarsız benzersizdir.

## Yapılandırma kontrol listesi (üretim)

- [ ] `JWT_ACCESS_SECRET` ve `JWT_REFRESH_SECRET` güçlü ve **birbirinden farklı**.
- [ ] `DATABASE_URL` TLS'li ve `rejectUnauthorized: true`.
- [ ] `CORS_ORIGINS` yalnızca gerçek istemci kaynaklarını içerir.
- [ ] `ANTHROPIC_API_KEY` yalnızca sunucu ortamında; repoya asla girmez.
- [ ] Reverse proxy TLS sonlandırması + HSTS aktif.
- [ ] Düzenli bağımlılık güvenlik taraması (`npm audit`).
