import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/secure_store.dart';
import '../models/profile.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AppState extends ChangeNotifier {
  final _api = ApiClient.instance;
  final _store = SecureStore.instance;

  AuthStatus status = AuthStatus.unknown;
  String? displayName;
  String? email;
  bool onboardingComplete = false;
  Profile? profile;

  /// Demo modu: backend olmadan uygulamayı gezmek için. Hiçbir ağ çağrısı yapılmaz.
  bool demo = false;

  void enterDemo() {
    demo = true;
    displayName = 'Demo Kullanıcı';
    email = 'demo@quantora.app';
    // Varsayılan bir profil ver: demo doğrudan ana ekrana gider, takılmaz.
    profile = Profile(
      sex: 'female',
      birthYear: 1995,
      heightCm: 170,
      weightKg: 70,
      activityLevel: 'moderate',
      goal: 'lose',
      dietType: 'omnivore',
      allergies: const [],
      dislikedFoods: const [],
    );
    onboardingComplete = true;
    status = AuthStatus.signedIn;
    notifyListeners();
  }

  /// Called at startup: if we have a stored session, confirm it with the server.
  Future<void> bootstrap() async {
    final token = await _store.accessToken;
    if (token == null) {
      status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    try {
      await loadMe();
      status = AuthStatus.signedIn;
    } catch (_) {
      await _store.clear();
      status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<void> loadMe() async {
    final data = await _api.get('/me');
    final user = data['user'] as Map<String, dynamic>;
    displayName = user['displayName'] as String?;
    email = user['email'] as String?;
    onboardingComplete = data['onboardingComplete'] as bool? ?? false;
    final p = data['profile'];
    profile = p is Map<String, dynamic> ? Profile.fromJson(p) : null;
  }

  Future<void> register(String email, String password, String name) async {
    final data = await _api.post('/auth/register',
        body: {'email': email, 'password': password, 'displayName': name}, auth: false);
    await _completeAuth(data);
  }

  Future<void> login(String email, String password) async {
    final data = await _api.post('/auth/login',
        body: {'email': email, 'password': password}, auth: false);
    await _completeAuth(data);
  }

  Future<void> _completeAuth(Map<String, dynamic> data) async {
    await _store.saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
    await loadMe();
    status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> saveProfile(Profile p) async {
    if (!demo) await _api.patch('/profile', body: p.toJson());
    profile = p;
    onboardingComplete = true;
    notifyListeners();
  }

  Future<void> savePantry(List<Map<String, String>> items) async {
    if (demo) return;
    await _api.patch('/pantry', body: {'items': items});
  }

  Future<void> logout() async {
    final refresh = await _store.refreshToken;
    try {
      if (refresh != null) {
        await _api.post('/auth/logout', body: {'refreshToken': refresh}, auth: false);
      }
    } catch (_) {
      // ignore network errors on logout
    }
    await _store.clear();
    status = AuthStatus.signedOut;
    displayName = null;
    email = null;
    profile = null;
    onboardingComplete = false;
    demo = false;
    notifyListeners();
  }
}
