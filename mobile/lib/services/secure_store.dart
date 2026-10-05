import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens are kept in platform-encrypted storage (Android Keystore via
/// EncryptedSharedPreferences), never in plain SharedPreferences, so they are
/// not trivially readable on a compromised device.
class SecureStore {
  SecureStore._();
  static final SecureStore instance = SecureStore._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<String?> get accessToken => _storage.read(key: _kAccess);
  Future<String?> get refreshToken => _storage.read(key: _kRefresh);

  Future<void> updateAccess(String access) => _storage.write(key: _kAccess, value: access);

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }

  // ---- Günlük hatırlatma ayarı ----
  static const _kRemOn = 'reminder_on';
  static const _kRemH = 'reminder_hour';
  static const _kRemM = 'reminder_min';

  Future<bool> reminderEnabled() async => (await _storage.read(key: _kRemOn)) == '1';

  Future<(int, int)> reminderTime() async {
    final h = int.tryParse(await _storage.read(key: _kRemH) ?? '') ?? 18;
    final m = int.tryParse(await _storage.read(key: _kRemM) ?? '') ?? 0;
    return (h, m);
  }

  Future<void> setReminder(bool on, int? hour, int? minute) async {
    await _storage.write(key: _kRemOn, value: on ? '1' : '0');
    if (hour != null) await _storage.write(key: _kRemH, value: '$hour');
    if (minute != null) await _storage.write(key: _kRemM, value: '$minute');
  }
}
