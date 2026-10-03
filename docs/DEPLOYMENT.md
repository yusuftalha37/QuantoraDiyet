# Kurulum ve Dağıtım

> Bu adımlar internet erişimi gerektirir (bağımlılık indirme, derleme).

## Backend

### Gereksinimler
- Node.js >= 18.17
- PostgreSQL >= 14

### Adımlar
```bash
cd backend
cp .env.example .env
# .env içinde en az şunları doldur:
#   DATABASE_URL, JWT_ACCESS_SECRET, JWT_REFRESH_SECRET
#   (AI için) AI_PROVIDER=anthropic ve ANTHROPIC_API_KEY
#   Güçlü secret üretmek için: openssl rand -hex 48

npm install
npm run db:migrate     # şemayı oluşturur
npm run dev            # geliştirme (http://localhost:4000)
```

### Üretim derlemesi
```bash
npm run build
NODE_ENV=production node dist/server.js
```
Üretimde süreç, zayıf/eksik yapılandırmada başlamayı reddeder (bkz. `src/config/env.ts`).

### AI olmadan çalıştırma
`AI_PROVIDER=none` (veya `ANTHROPIC_API_KEY` boş) olduğunda sistem,
ağ gerektirmeyen **deterministik yedek motoru** kullanır. Uygulama tamamen
çalışır; planlar yerel tarif veritabanından üretilir.

## Sağlık kontrolü
```
GET /health  ->  { "status": "ok", ... }
```

## API uç noktaları (özet)
| Yöntem | Yol | Açıklama | Kimlik |
|-------|-----|----------|--------|
| POST | `/api/v1/auth/register` | Kayıt | - |
| POST | `/api/v1/auth/login` | Giriş | - |
| POST | `/api/v1/auth/refresh` | Token yenile | - |
| POST | `/api/v1/auth/logout` | Çıkış | - |
| POST | `/api/v1/auth/logout-all` | Tüm oturumları kapat | Bearer |
| GET | `/api/v1/me` | Profil + onboarding durumu | Bearer |
| PATCH | `/api/v1/profile` | Profili kaydet | Bearer |
| GET/PATCH | `/api/v1/pantry` | Evdeki malzemeler | Bearer |
| GET | `/api/v1/targets` | Kalori/makro hedefleri | Bearer |
| POST | `/api/v1/plans` | Plan üret (diet/daily × daily/weekly/monthly) | Bearer |
| GET | `/api/v1/plans` | Plan geçmişi | Bearer |
| GET | `/api/v1/plans/:id` | Tek plan | Bearer |

## Mobil (Flutter)

```bash
cd mobile
flutter create .        # android/ios platform klasörlerini üretir (ilk kez)
flutter pub get
# Backend adresini ver (emülatör host = 10.0.2.2):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api/v1
```

Google Play'e çıkış için `docs/GOOGLE_PLAY.md`.
