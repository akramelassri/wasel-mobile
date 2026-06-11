import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wasel/api/auth_service.dart';
import 'package:wasel/api/location_service.dart';
import 'package:wasel/config.dart';

enum DeliveryServiceError { unauthorized, network, server }

class DeliveryResult {
  final Map<String, dynamic>? data;
  final DeliveryServiceError? error;

  const DeliveryResult.success(this.data) : error = null;
  const DeliveryResult.failure(this.error) : data = null;

  bool get isSuccess => error == null;
}

class DeliveryService {
  static const _timeout = Duration(seconds: 15);

  // ── helper for safe json decode ────────────────────────────────

  static Map<String, dynamic> _safeDecode(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    return jsonDecode(body) as Map<String, dynamic>;
  }

  // ── create delivery ────────────────────────────────────────────

  static Future<DeliveryResult> createDelivery({
    required AuthService authService,
    required AddressResult pickupAddress,
    required AddressResult dropoffAddress,
    required double weight,
    required bool isFragile,
  }) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DeliveryResult.failure(DeliveryServiceError.unauthorized);
    }

    try {
      final response = await http
          .post(
            Uri.parse('$API/api/deliveries'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'pickupAddress': pickupAddress.toJson(),
              'dropoffAddress': dropoffAddress.toJson(),
              'parcel': {
                'description': 'Standard parcel', // FIX: Required by backend
                'volume': 1.0, // FIX: Required by backend
                'weight': weight,
                'isFragile': isFragile,
              },
              'paymentMethod': 1,
            }),
          )
          .timeout(_timeout);

      switch (response.statusCode) {
        case 200:
        case 201:
          return DeliveryResult.success(_safeDecode(response.body));
        case 400: // 🚨 ADD THIS CASE
          print('🚨 BACKEND REJECTED DELIVERY: ${response.body}');
          return const DeliveryResult.failure(DeliveryServiceError.server);
        case 401:
        case 403:
          return const DeliveryResult.failure(
            DeliveryServiceError.unauthorized,
          );
        default:
          return const DeliveryResult.failure(DeliveryServiceError.server);
      }
    } catch (_) {
      return const DeliveryResult.failure(DeliveryServiceError.network);
    }
  }

  // ── get my deliveries ──────────────────────────────────────────

  static Future<DeliveryResult> getMyDeliveries({
    required AuthService authService,
    int page = 1,
    int pageSize = 10,
  }) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DeliveryResult.failure(DeliveryServiceError.unauthorized);
    }

    try {
      final response = await http
          .get(
            Uri.parse('$API/api/deliveries/my?page=$page&pageSize=$pageSize'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);

      switch (response.statusCode) {
        case 200:
          return DeliveryResult.success(_safeDecode(response.body));
        case 401:
        case 403:
          return const DeliveryResult.failure(
            DeliveryServiceError.unauthorized,
          );
        default:
          return const DeliveryResult.failure(DeliveryServiceError.server);
      }
    } catch (_) {
      return const DeliveryResult.failure(DeliveryServiceError.network);
    }
  }

  // ── get delivery by id ─────────────────────────────────────────

  static Future<DeliveryResult> getDelivery({
    required AuthService authService,
    required String id,
  }) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DeliveryResult.failure(DeliveryServiceError.unauthorized);
    }

    try {
      final response = await http
          .get(
            Uri.parse('$API/api/deliveries/$id'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);

      switch (response.statusCode) {
        case 200:
          return DeliveryResult.success(_safeDecode(response.body));
        case 401:
        case 403:
          return const DeliveryResult.failure(
            DeliveryServiceError.unauthorized,
          );
        case 404:
          return const DeliveryResult.failure(DeliveryServiceError.server);
        default:
          return const DeliveryResult.failure(DeliveryServiceError.server);
      }
    } catch (_) {
      return const DeliveryResult.failure(DeliveryServiceError.network);
    }
  }

  // ── get active deliveries ──────────────────────────────────────

  static Future<DeliveryResult> getActiveDeliveries({
    required AuthService authService,
  }) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DeliveryResult.failure(DeliveryServiceError.unauthorized);
    }

    try {
      final response = await http
          .get(
            Uri.parse('$API/api/deliveries/my/active'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);

      switch (response.statusCode) {
        case 200:
          // FIX: Wrap the backend list into a Map to satisfy DeliveryResult
          final decoded = jsonDecode(response.body);
          final map = decoded is List
              ? {'items': decoded}
              : decoded as Map<String, dynamic>;
          return DeliveryResult.success(map);
        case 401:
        case 403:
          return const DeliveryResult.failure(
            DeliveryServiceError.unauthorized,
          );
        default:
          return const DeliveryResult.failure(DeliveryServiceError.server);
      }
    } catch (_) {
      return const DeliveryResult.failure(DeliveryServiceError.network);
    }
  }

  // ── cancel delivery ────────────────────────────────────────────

  static Future<DeliveryResult> cancelDelivery({
    required AuthService authService,
    required String id,
    String? reason,
  }) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DeliveryResult.failure(DeliveryServiceError.unauthorized);
    }

    try {
      final response = await http
          .post(
            Uri.parse('$API/api/deliveries/$id/cancel'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'reason': reason ?? ''}),
          )
          .timeout(_timeout);

      switch (response.statusCode) {
        case 200:
          return DeliveryResult.success(_safeDecode(response.body));
        case 401:
        case 403:
          return const DeliveryResult.failure(
            DeliveryServiceError.unauthorized,
          );
        case 404:
          return const DeliveryResult.failure(DeliveryServiceError.server);
        default:
          return const DeliveryResult.failure(DeliveryServiceError.server);
      }
    } catch (_) {
      return const DeliveryResult.failure(DeliveryServiceError.network);
    }
  }

  // ── estimate delivery ──────────────────────────────────────────

  static Future<DeliveryResult> estimateDelivery({
    required AuthService authService,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required double weight,
    required bool isFragile,
  }) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DeliveryResult.failure(DeliveryServiceError.unauthorized);
    }

    try {
      final uri = Uri.parse('$API/api/deliveries/estimate').replace(
        queryParameters: {
          'pickupLat': pickupLat.toString(),
          'pickupLng': pickupLng.toString(),
          'dropoffLat': dropoffLat.toString(),
          'dropoffLng': dropoffLng.toString(),
          'weight': weight.toString(),
          'isFragile': isFragile.toString(),
        },
      );

      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);

      switch (response.statusCode) {
        case 200:
          return DeliveryResult.success(_safeDecode(response.body));
        case 401:
        case 403:
          return const DeliveryResult.failure(
            DeliveryServiceError.unauthorized,
          );
        default:
          return const DeliveryResult.failure(DeliveryServiceError.server);
      }
    } catch (_) {
      return const DeliveryResult.failure(DeliveryServiceError.network);
    }
  }
}
