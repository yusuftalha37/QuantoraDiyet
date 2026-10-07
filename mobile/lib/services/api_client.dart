import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'secure_store.dart';

class ApiException implements Exception {
  final int status;
  final String code;
  final String message;
  ApiException(this.status, this.code, this.message);
  @override
  String toString() => message;
}

/// Thin HTTP client that attaches the Bearer access token, and transparently
/// refreshes it once on a 401 before retrying the original request. All request
/// bodies are JSON; all errors are normalised to [ApiException].
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final _store = SecureStore.instance;
  bool _refreshing = false;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
    bool auth = true,
    bool retryOn401 = true,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await _store.accessToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    final request = http.Request(method, _uri(path))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    final streamed = await http.Client()
        .send(request)
        .timeout(AppConfig.requestTimeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401 && auth && retryOn401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return _send(method, path, body: body, auth: auth, retryOn401: false);
      }
    }

    return _parse(response);
  }

  Map<String, dynamic> _parse(http.Response response) {
    final isJson = (response.headers['content-type'] ?? '').contains('application/json');
    final dynamic data = response.body.isNotEmpty && isJson ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    }

    final err = (data is Map && data['error'] is Map) ? data['error'] as Map : null;
    throw ApiException(
      response.statusCode,
      err?['code']?.toString() ?? 'ERROR',
      err?['message']?.toString() ?? 'İstek başarısız (${response.statusCode})',
    );
  }

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final refresh = await _store.refreshToken;
      if (refresh == null) return false;
      final data = await _send('POST', '/auth/refresh',
          body: {'refreshToken': refresh}, auth: false, retryOn401: false);
      await _store.saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
      return true;
    } catch (_) {
      await _store.clear();
      return false;
    } finally {
      _refreshing = false;
    }
  }

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);
  Future<Map<String, dynamic>> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);
  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);
  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);
}
