import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wasel/config.dart';
import 'package:wasel/api/auth_service.dart';

enum UserServiceError { unauthorized, network, server }

class UserResult {
  final Map<String, dynamic>? data;
  final UserServiceError? error;

  const UserResult.success(this.data) : error = null;
  const UserResult.failure(this.error) : data = null;

  bool get isSuccess => error == null;
}

class UserService {
  static const _timeout = Duration(seconds: 10);

  // ── helper for safe json decode ────────────────────────────────
  static Map<String, dynamic> _safeDecode(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    return jsonDecode(body) as Map<String, dynamic>;
  }

  static Future<UserResult> getUserInfo(AuthService authService) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const UserResult.failure(UserServiceError.unauthorized);
    }

    try {
      final response = await http
          .get(
            Uri.parse('$API/api/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout); // 1. Added timeout protection

      switch (response.statusCode) {
        case 200:
          // 2. Safely decode to prevent silent parsing crashes
          return UserResult.success(_safeDecode(response.body));
        case 401:
        case 403:
          return const UserResult.failure(UserServiceError.unauthorized);
        default:
          return const UserResult.failure(UserServiceError.server);
      }
    } catch (_) {
      return const UserResult.failure(UserServiceError.network);
    }
  }
}
