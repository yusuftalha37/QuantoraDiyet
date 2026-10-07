# Google Play'e Yayınlama Rehberi

Flutter uygulamasını Google Play'de yayınlamak için adımlar.

## 1. Platform klasörünü üret
İlk kez:
```bash
cd mobile
flutter create .
```

## 2. Uygulama kimliği ve adı
`mobile/android/app/build.gradle` içinde:
```gradle
android {
    namespace "com.quantora.diyet"
    defaultConfig {
        applicationId "com.quantora.diyet"   // Play'de benzersiz olmalı
        minSdkVersion 23
        targetSdkVersion flutter.targetSdkVersion
        versionCode 1
        versionName "1.0.0"
    }
}
```

## 3. İnternet izni ve ağ güvenliği
`mobile/android/app/src/main/AndroidManifest.xml` içinde `<manifest>` altına:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
> Üretimde backend **HTTPS** olmalıdır. Geliştirmede `http://10.0.2.2` için
> geçici olarak `android:usesCleartextTraffic="true"` eklenebilir; üretim
> derlemesinde **kaldırın**. En iyisi debug/release için ayrı
> `networkSecurityConfig` kullanmaktır.

## 4. Yayın imzalama (upload key)
Anahtar üret:
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
`mobile/android/key.properties` oluştur (repoya **girmez**, .gitignore'da):
```
storePassword=****
keyPassword=****
keyAlias=upload
storeFile=/mutlak/yol/upload-keystore.jks
```
`mobile/android/app/build.gradle` içinde signing config:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

## 5. App Bundle üret
```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.alanadiniz.com/api/v1
```
Çıktı: `build/app/outputs/bundle/release/app-release.aab`

## 6. Play Console
1. https://play.google.com/console → uygulama oluştur.
2. **Play App Signing**'i etkinleştir (Google imzalama anahtarını yönetir;
   senin `upload-keystore.jks` yalnızca yükleme anahtarıdır — güvenle sakla/yedekle).
3. `.aab` dosyasını iç test / üretim kanalına yükle.
4. Zorunlu beyanlar:
   - **Gizlilik politikası URL'si** (hesap/e-posta ve beslenme verisi işlendiği için).
   - **Data safety** formu: toplanan veriler (e-posta, profil, pantry, planlar),
     şifreli iletim ve saklama.
   - İçerik derecelendirmesi, hedef kitle.
5. Mağaza kaydı: ekran görüntüleri, açıklama, ikon.

## 7. Sürüm yükseltme
Her yeni yüklemede `versionCode` artır (`pubspec.yaml`'da `version: 1.0.1+2`
→ `+2` versionCode olur).

## Güvenlik hatırlatmaları
- `key.properties`, `*.jks`, `google-services.json` **repoya girmez** (zaten .gitignore'da).
- API anahtarları yalnızca backend'de; `.aab` içine hiçbir sır konmaz.

## 8. Uygulamayı ÜCRETLİ yapma (paralı satış)
1. Play Console → uygulaman → **Monetize → Ürünler değil**, doğrudan
   **Setup → App pricing** (Uygulama fiyatı) → **Paid** seç.
2. Fiyatı belirle; Google ülkelere göre yerel fiyatları önerir (dilersen düzenle).
3. **Merchant (satıcı) hesabı** gerekir: Play Console → **Payments profile**
   oluştur (vergi/banka bilgileri). Bu olmadan ücretli yayınlayamazsın.
4. Komisyon: Google satıştan pay alır (genelde %15–30).
5. Not: Bir uygulama **yayınlandıktan sonra ücretsizden ücretliye çevrilemez**
   (tersi mümkün). Ücretli olacaksa ilk yayından önce Paid seç.

## 9. Hesap + sunucu kullandığın için ZORUNLU olanlar
Backend'e (hesap/senkron) geçtiğin an kişisel veri topluyorsun demektir:
- **Gizlilik politikası URL'si zorunlu.** Bir metin hazırla, bir yerde yayınla
  (ör. basit bir web sayfası / GitHub Pages). Örnek taslak:
  `docs/PRIVACY_POLICY_ornek.md`.
- **Data Safety formu** gerçeği yansıtmalı: toplanan veriler (e-posta, profil,
  evdeki malzemeler, öneri geçmişi), sunucuda saklanıyor, iletim şifreli (HTTPS),
  kullanıcı hesabını/verisini silebiliyor (hesap silme akışı eklemen istenebilir).
- Yanlış/eksik beyan uygulamanın reddine veya kaldırılmasına yol açar.

## 10. Özet: hangi adım kimde?
- **Bende (kod):** backend, Dockerfile, `render.yaml`, uygulama–hesap bağlantısı, rehberler.
- **Sende (hesap/ücret):** sunucuyu kurup aylık ödemek (`docs/DEPLOY_BACKEND.md`),
  gizlilik politikasını yayınlamak, Play'de Merchant hesabı + fiyat belirlemek,
  imzalama anahtarını oluşturup saklamak.
