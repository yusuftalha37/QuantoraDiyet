# Google ile Giriş Kurulumu

Uygulamada "Google ile giriş yap" düğmesi, sen yapılandırana kadar görünmez.
Çalışması için Google Cloud'da OAuth kimlikleri oluşturman gerekir (ücretsiz).

> Kod hazır. Buradaki adımlar senin Google hesabında yapılır; ben yapamam.

## 1. Google Cloud'da OAuth kimlikleri
1. https://console.cloud.google.com → yeni proje oluştur.
2. **APIs & Services → OAuth consent screen** → "External" → uygulama adı,
   destek e-postası, geliştirici e-postası. Yayına al (veya test kullanıcısı ekle).
3. **Credentials → Create Credentials → OAuth client ID**:
   - **Web application** oluştur → bir **Web client ID** alırsın. Bu, hem
     uygulamadaki `GOOGLE_SERVER_CLIENT_ID` hem de backend'in doğrulama
     audience'ı olacak.
   - **Android** oluştur → paket adı `com.quantora.diyet` (applicationId ile
     aynı) + imzalama anahtarının **SHA-1** parmak izi.
     - Play App Signing kullanıyorsan SHA-1'i Play Console → Setup → App
       integrity → App signing'den al. (Yükleme anahtarının SHA-1'ini de ekle.)
     - Yerel keystore SHA-1: `keytool -list -v -keystore upload-keystore.jks -alias upload`

## 2. Backend'e client ID'leri ver
Barındırdığın backend'in ortam değişkenine (virgülle) **kabul edilen** client
ID'lerini yaz:
```
GOOGLE_CLIENT_IDS=WEB_CLIENT_ID.apps.googleusercontent.com
```
(Genelde Web client ID yeterli; Android `signIn` bu Web ID'yi serverClientId
olarak kullanır ve idToken'ın audience'ı bu olur.)

## 3. Uygulamayı derlerken Web client ID'yi ver
```
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://senin-backend/api/v1 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=WEB_CLIENT_ID.apps.googleusercontent.com
```
GitHub Actions ("Play için imzalı AAB") kullanıyorsan `GOOGLE_SERVER_CLIENT_ID`
ve `API_BASE_URL` secret'larını ekle; iş akışı bunları otomatik kullanır.

## Nasıl çalışır (özet)
- Uygulama Google ile oturum açar, bir **idToken** alır, backend'e gönderir.
- Backend idToken'ı Google'da doğrular (audience = senin Web client ID),
  e-postaya göre kullanıcıyı bulur/oluşturur ve kendi JWT'sini verir.
- Böylece Google kullanıcıları da hesap + senkron akışına dâhil olur.
