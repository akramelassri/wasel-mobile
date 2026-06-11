import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:wasel/config.dart';
import 'dart:convert';

enum UserMode { client, driver }

class AuthService {
  String? _accessToken;
  String? _refreshToken;
  UserMode? _cachedMode;

  final _appAuth = FlutterAppAuth();
  final _storage = const FlutterSecureStorage();

  // ── token persistence ──────────────────────────────────────────

  Future<String?> getAccessToken() async {
    _accessToken ??= await _storage.read(key: 'access-token');
    return _accessToken;
  }

  Future<String?> _getRefreshToken() async {
    _refreshToken ??= await _storage.read(key: 'refresh-token');
    return _refreshToken;
  }

  Future<void> _persistTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    await Future.wait([
      _storage.write(key: 'access-token', value: access),
      _storage.write(key: 'refresh-token', value: refresh),
    ]);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await Future.wait([
      _storage.delete(key: 'access-token'),
      _storage.delete(key: 'refresh-token'),
    ]);
  }

  // ── mode ───────────────────────────────────────────────────────

  Future<UserMode> getMode() async {
    if (_cachedMode != null) return _cachedMode!;

    final stored = await _storage.read(key: 'user-mode');
    _cachedMode = stored == 'driver' ? UserMode.driver : UserMode.client;
    return _cachedMode!;
  }

  Future<void> setMode(UserMode mode) async {
    _cachedMode = mode;
    await _storage.write(
      key: 'user-mode',
      value: mode == UserMode.driver ? 'driver' : 'client',
    );
  }

  // ── auth check ─────────────────────────────────────────────────

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    if (token == null) return false;

    if (await _pingAuthMe(token)) return true;

    final refreshed = await _tryRefresh();
    if (!refreshed) {
      await clearTokens();
      return false;
    }

    final newToken = await getAccessToken();
    if (newToken != null && await _pingAuthMe(newToken)) return true;

    await clearTokens();
    return false;
  }

  Future<bool> _pingAuthMe(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$API/api/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final result = await _appAuth.token(
        TokenRequest(
          'wasel-mobile',
          'com.example.wasel://oauthredirect',
          discoveryUrl:
              '$API/auth/realms/wasel/.well-known/openid-configuration',
          refreshToken: refreshToken,
        ),
      );

      if (result?.accessToken == null || result?.refreshToken == null) {
        return false;
      }

      await _persistTokens(result!.accessToken!, result.refreshToken!);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── login / register ───────────────────────────────────────────

  Future<bool> login() async => _authActions(['login']);

  Future<bool> register() async => _authActions(['create']);

  Future<bool> _authActions(List<String> actions) async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          'wasel-mobile',
          'com.example.wasel://oauthredirect',
          discoveryUrl:
              '$API/auth/realms/wasel/.well-known/openid-configuration',
          scopes: ['openid', 'profile', 'email'],
          promptValues: actions,
        ),
      );

      if (result?.accessToken == null || result?.refreshToken == null) {
        return false;
      }

      // Call the backend to ensure the user exists in PostgreSQL
      // before considering the login successful.
      final isSynced = await _syncUserWithBackend(result!.accessToken!);
      if (!isSynced) {
        print('🚨 AUTH ERROR: Backend Sync Failed (returned false)');
        return false;
      }

      await _persistTokens(result.accessToken!, result.refreshToken!);
      return true;
    } on PlatformException catch (e) {
      print('🚨 PLATFORM ERROR: ${e.message} | ${e.details}');
      return false;
    } catch (e) {
      print('🚨 AUTH EXCEPTION: $e');
      return false;
    }
  }

  // ── backend sync ───────────────────────────────────────────────

  Future<bool> _syncUserWithBackend(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse('$API/api/auth/sync'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('🚨 SYNC STATUS CODE: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('🚨 SYNC EXCEPTION: $e');
      return false;
    }
  }

  Future<bool> switchAppMode(bool toDriver) async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;

      final int targetMode = toDriver ? 1 : 0;
      final url = Uri.parse('$API/api/users/me/preferences');

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'activeAppMode': targetMode,
          'preferredMode': targetMode,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Mode switched successfully on backend!');
        return true;
      } else {
        print(
          '🚨 Failed to switch mode: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('🚨 Exception switching mode: $e');
      return false;
    }
  }
}
