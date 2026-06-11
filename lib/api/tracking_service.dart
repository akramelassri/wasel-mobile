import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:wasel/api/auth_service.dart';
import 'package:wasel/config.dart';

enum TrackingServiceError { unauthorized, network, server }

class TrackingResult {
  final LatLng? position;
  final TrackingServiceError? error;

  const TrackingResult.success(this.position) : error = null;
  const TrackingResult.failure(this.error) : position = null;

  bool get isSuccess => error == null;
}

class TrackingService {
  static const _timeout = Duration(seconds: 10);

  static Future<TrackingResult> getDeliveryLastPosition({
    required AuthService authService,
    required String deliveryId,
  }) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const TrackingResult.failure(TrackingServiceError.unauthorized);
    }

    try {
      final response = await http
          .get(
            Uri.parse('$API/api/tracking/deliveries/$deliveryId/last-position'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body);

          // ── SAFE PARSING ───────────────────────────────────────────────
          // Backend sends {"latitude": "33.5", "longitude": "-7.5"}
          // We must safely parse Strings to Doubles to prevent TypeErrors
          final latString = data['latitude']?.toString();
          final lngString = data['longitude']?.toString();

          final latitude = latString != null
              ? double.tryParse(latString)
              : null;
          final longitude = lngString != null
              ? double.tryParse(lngString)
              : null;

          if (latitude != null && longitude != null) {
            return TrackingResult.success(LatLng(latitude, longitude));
          }
          return const TrackingResult.failure(TrackingServiceError.server);

        case 401:
        case 403:
          return const TrackingResult.failure(
            TrackingServiceError.unauthorized,
          );
        case 404:
          // Valid case: Driver hasn't broadcasted a position yet
          return const TrackingResult.success(null);
        default:
          return const TrackingResult.failure(TrackingServiceError.server);
      }
    } catch (_) {
      return const TrackingResult.failure(TrackingServiceError.network);
    }
  }
}
