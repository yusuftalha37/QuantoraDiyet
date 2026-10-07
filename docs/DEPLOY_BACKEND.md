# Backend'i Yayınlama (Hesap + Senkron için)

Hesap sistemi ve cihazlar arası senkron için backend'in internette, HTTPS'li
bir adreste çalışması gerekir. Kod hazır; burada **sen** bir yere kurarsın.

> Bunlar senin yapman gereken, ücretli adımlardır (barındırma + veritabanı
> aylık ücret ister). Ben kuramam/ödeyemem; ama dosyalar ve adımlar hazır.

## Seçenek 1 — Render (en kolay, blueprint ile)

1. https://render.com → ücretsiz hesap aç, GitHub'ı bağla.
2. **New + → Blueprint** → bu repoyu (`QuantoraDiyet`) seç.
3. Render, repodaki `render.yaml`'a göre:
   - `quantoradiyet-api` (web servis, Docker) ve
   - `quantoradiyet-db` (PostgreSQL)
   oluşturur. JWT secret'ları otomatik üretir, veritabanını bağlar,
   ilk açılışta migration'ları çalıştırır (`preDeployCommand`).
4. Plan: gerçek kullanım için **Starter** (ücretli) seç. (Ücretsiz Postgres
   süreli olabilir.)
5. Deploy bitince servisin bir adresi olur:
   `https://quantoradiyet-api.onrender.com`
6. Sağlık kontrolü: tarayıcıda `.../health` → `{"status":"ok"}` görmelisin.
7. **API adresin:** `https://quantoradiyet-api.onrender.com/api/v1`

## Seçenek 2 — Railway / Fly.io / kendi sunucun (VPS)

- **Railway:** New Project → Deploy from repo → root `backend`, Docker.
  Add PostgreSQL plugin → `DATABASE_URL` otomatik gelir. Env'leri (JWT
  secret'ları `openssl rand -hex 48` ile üret) ekle. Deploy sonrası bir kez
  `node dist/db/migrate.js` çalıştır.
- **VPS (Docker):**
  ```bash
  cd backend
  docker build -t quantoradiyet-api .
  docker run -d -p 4000:4000 \
    -e NODE_ENV=production \
    -e DATABASE_URL="postgres://..." \
    -e JWT_ACCESS_SECRET="$(openssl rand -hex 48)" \
    -e JWT_REFRESH_SECRET="$(openssl rand -hex 48)" \
    quantoradiyet-api
  # İlk kurulumda migration:
  docker exec <container> node dist/db/migrate.js
  ```
  Önüne HTTPS için bir reverse proxy (Caddy/Nginx + Let's Encrypt) koy.

## Zorunlu ortam değişkenleri

| Değişken | Açıklama |
|----------|----------|
| `DATABASE_URL` | PostgreSQL bağlantısı (barındırıcı verir) |
| `JWT_ACCESS_SECRET` | Güçlü rastgele (≥32), `openssl rand -hex 48` |
| `JWT_REFRESH_SECRET` | Yukarıdakinden **farklı**, güçlü rastgele |
| `NODE_ENV` | `production` |
| `CORS_ORIGINS` | Mobil için boş bırakılabilir |
| `AI_PROVIDER` | `none` (varsayılan) veya `anthropic` |
| `ANTHROPIC_API_KEY` | Yalnızca gerçek AI istersen (karakter başına ücret) |

## Uygulamayı backend'e bağlama

Uygulama derlenirken backend adresini ver:
```bash
cd mobile
flutter build apk --release \
  --dart-define=API_BASE_URL=https://quantoradiyet-api.onrender.com/api/v1
```
GitHub Actions ile derliyorsan: Actions → "Android APK derle" → **Run workflow**
→ `api_base_url` alanına bu adresi yaz.

Bundan sonra kullanıcılar **hesap açıp giriş** yapar; profil, evdeki malzemeler
ve geçmiş öneriler sunucuda saklanır ve farklı cihazlarda senkron olur.
(İlk ekrandaki "Demo olarak dene" seçeneği hesapsız, yerel deneme olarak kalır.)

## Aylık maliyet (yaklaşık, değişebilir)
- Barındırma (web servis): ~7–25 USD/ay
- Yönetilen PostgreSQL: ~7–20 USD/ay
- (Opsiyonel) Anthropic AI: kullanım kadar (karakter başına)
