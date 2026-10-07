/// App-wide configuration.
///
/// `apiBaseUrl` can be overridden at build time:
///   flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
///
/// For the Android emulator, the host machine is reachable at 10.0.2.2.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api/v1',
  );

  static const String appName = 'Bugün Ne Pişirsem?';
  static const Duration requestTimeout = Duration(seconds: 35);

  /// Google ile giriş için WEB OAuth client ID'si (serverClientId).
  /// Boşsa Google giriş düğmesi görünmez.
  ///   flutter build apk --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
  static bool get googleEnabled => googleServerClientId.isNotEmpty;
}
