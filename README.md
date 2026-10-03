# QuantoraDiyet

Yapay zekâ destekli diyet ve yemek planlama uygulaması. Kullanıcı hesabıyla
giriş yapar, evinde bulunan malzemeleri ve hedefini (diyet mi yoksa günlük
yemek mi) belirtir; sistem ona **günlük / haftalık / aylık** yemek listesi
üretir.

> Durum: Mimari iskelet ve tüm kaynak kodu hazır. Bağımlılık kurulumu
> (`npm install`, `flutter pub get`) ve derleme adımları internet
> gerektirdiğinden ayrıca çalıştırılmalıdır (bkz. `docs/`).

## Mimari

```
QuantoraDiyet/
├── backend/        Node.js + TypeScript + Express API
│   ├── Güvenlik:   JWT (access+refresh), bcrypt, helmet, CORS,
│   │               rate-limit, zod doğrulama, parametreli SQL, loglama
│   ├── AI:         LLM sağlayıcı (Anthropic) + çevrimdışı deterministik
│   │               yedek motor, BMR/TDEE hesabı, plan üretimi
│   └── DB:         PostgreSQL (migration'lar `src/db/migrations`)
├── mobile/         Flutter uygulaması (Google Play hedefli)
│   ├── Giriş/Kayıt, güvenli token saklama (flutter_secure_storage)
│   ├── Onboarding: evdeki malzemeler + diyet/günlük tercihi + profil
│   └── Plan ekranları: günlük/haftalık/aylık
└── docs/           Güvenlik, kurulum ve Google Play yayınlama rehberleri
```

### Neden ayrı backend?

Yapay zekâ sağlayıcı API anahtarları ve iş mantığı **asla** mobil uygulamaya
gömülmez (APK tersine mühendislikle açılabilir). Tüm gizli anahtarlar backend'de
kalır; mobil uygulama yalnızca kendi kullanıcısının JWT'siyle backend'e konuşur.

## Hızlı başlangıç

### Backend
```bash
cd backend
cp .env.example .env        # değerleri doldur (JWT secret, DB, AI anahtarı)
npm install                 # internet gerekir
npm run db:migrate
npm run dev                 # http://localhost:4000
```

### Mobile
```bash
cd mobile
flutter pub get             # internet gerekir
# lib/config.dart içindeki apiBaseUrl'i backend adresine ayarla
flutter run
```

## Güvenlik özeti
Ayrıntılar `docs/SECURITY.md` içinde. Öne çıkanlar:
- Parolalar bcrypt (maliyet 12) ile hashlenir, düz metin asla saklanmaz/loglanmaz.
- JWT access (kısa ömür) + refresh (rotasyonlu, DB'de saklanan hash) modeli.
- Her istekte helmet güvenlik başlıkları, sıkı CORS, global + login özel rate-limit.
- Tüm girdiler zod ile şema doğrulamasından geçer; SQL yalnızca parametreli.
- Hata yanıtlarında yığın izi/iç detay sızdırılmaz; merkezî hata yönetimi.

## Yayınlama
`docs/GOOGLE_PLAY.md` — imzalama, app bundle (`.aab`) üretimi, Play Console adımları.
