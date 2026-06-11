import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wasel/api/auth_service.dart';
import 'package:wasel/api/user_service.dart';
import 'package:wasel/config.dart';
import 'package:wasel/model/available_delivery_model.dart';
import 'package:wasel/model/driver_mission_model.dart';
import 'package:wasel/model/driver_notification_model.dart';
import 'package:wasel/model/driver_profile_model.dart';
import 'package:wasel/model/driver_wallet_model.dart';

enum DriverApiError {
  unauthorized,
  conflict,
  notFound,
  badRequest,
  server,
  network,
}

class DriverApiResult<T> {
  final T? data;
  final DriverApiError? error;
  final String? message;

  const DriverApiResult.success(this.data) : error = null, message = null;

  const DriverApiResult.failure(this.error, {this.message}) : data = null;

  bool get isSuccess => error == null;
}

class DriverService {
  static const _defaultPageSize = 20;

  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  static Future<DriverApiResult<List<AvailableDelivery>>>
  fetchAvailableDeliveries(
    AuthService authService, {
    required double latitude,
    required double longitude,
    int page = 1,
    int pageSize = _defaultPageSize,
  }) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    try {
      final uri = Uri.parse(
        '$API/api/deliveries/available?latitude=$latitude&longitude=$longitude&radiusKm=1000&page=$page&pageSize=$pageSize',
      );
      final response = await http.get(uri, headers: _headers(token));
      // print the reselt to console
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (body['items'] as List<dynamic>?) ?? [];
        final deliveries = items
            .cast<Map<String, dynamic>>()
            .map(AvailableDelivery.fromJson)
            .toList();
        return DriverApiResult.success(deliveries);
      }

      if (response.statusCode == 400) {
        return DriverApiResult.failure(
          DriverApiError.badRequest,
          message: _extractApiMessage(response.body),
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DriverApiResult.failure(DriverApiError.unauthorized);
      }

      return DriverApiResult.failure(
        DriverApiError.server,
        message: 'Failed to load available deliveries.',
      );
    } catch (_) {
      return const DriverApiResult.failure(
        DriverApiError.network,
        message: 'Unable to reach the backend.',
      );
    }
  }

  static Future<DriverApiResult<List<DriverMission>>> fetchMyMissions(
    AuthService authService, {
    int page = 1,
    int pageSize = _defaultPageSize,
  }) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    try {
      final uri = Uri.parse(
        '$API/api/deliveries/my-missions?page=$page&pageSize=$pageSize',
      );
      final response = await http.get(uri, headers: _headers(token));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (body['items'] as List<dynamic>?) ?? [];
        final missions = items
            .cast<Map<String, dynamic>>()
            .map(DriverMission.fromJson)
            .toList();
        return DriverApiResult.success(missions);
      }

      if (response.statusCode == 400) {
        return DriverApiResult.failure(
          DriverApiError.badRequest,
          message: _extractApiMessage(response.body),
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DriverApiResult.failure(DriverApiError.unauthorized);
      }

      return DriverApiResult.failure(
        DriverApiError.server,
        message: 'Failed to load missions.',
      );
    } catch (_) {
      return const DriverApiResult.failure(
        DriverApiError.network,
        message: 'Unable to reach the backend.',
      );
    }
  }

  static Future<DriverApiResult<void>> respondToDelivery(
    AuthService authService,
    String deliveryId,
    bool accept,
  ) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    try {

      final response = await http.post(
        Uri.parse('$API/api/deliveries/$deliveryId/response'),
        headers: _headers(token),
        body: jsonEncode({'accept': accept}),
      );

      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        return const DriverApiResult.success(null);
      }

      if (response.statusCode == 404) {
        return const DriverApiResult.failure(DriverApiError.notFound);
      }

      if (response.statusCode == 409) {
        return DriverApiResult.failure(
          DriverApiError.conflict,
          message: _extractApiMessage(response.body),
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DriverApiResult.failure(DriverApiError.unauthorized);
      }

      return DriverApiResult.failure(
        DriverApiError.server,
        message: 'Could not respond to delivery.',
      );
    } catch (_) {
      return const DriverApiResult.failure(
        DriverApiError.network,
        message: 'Unable to reach the backend.',
      );
    }
  }

  static Future<DriverApiResult<List<DriverNotification>>> fetchNotifications(
    AuthService authService, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    try {
      final uri = Uri.parse(
        '$API/api/notifications/my?page=$page&pageSize=$pageSize',
      );
      final response = await http.get(uri, headers: _headers(token));

      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (body['items'] as List<dynamic>?) ?? [];
        final notifications = items
            .cast<Map<String, dynamic>>()
            .map(DriverNotification.fromJson)
            .toList();
        return DriverApiResult.success(notifications);
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DriverApiResult.failure(DriverApiError.unauthorized);
      }

      return const DriverApiResult.failure(
        DriverApiError.server,
        message: 'Failed to load notifications.',
      );
    } catch (_) {
      return const DriverApiResult.failure(
        DriverApiError.network,
        message: 'Unable to reach the backend.',
      );
    }
  }

  static Future<DriverApiResult<void>> markNotificationRead(
    AuthService authService,
    String notificationId,
  ) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    try {
      final response = await http.patch(
        Uri.parse('$API/api/notifications/$notificationId/read'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        return const DriverApiResult.success(null);
      }

      if (response.statusCode == 404) {
        return const DriverApiResult.failure(DriverApiError.notFound);
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DriverApiResult.failure(DriverApiError.unauthorized);
      }

      return const DriverApiResult.failure(
        DriverApiError.server,
        message: 'Could not mark notification as read.',
      );
    } catch (_) {
      return const DriverApiResult.failure(
        DriverApiError.network,
        message: 'Unable to reach the backend.',
      );
    }
  }

  static Future<DriverApiResult<void>> markAllNotificationsRead(
    AuthService authService,
  ) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    try {
      final response = await http.patch(
        Uri.parse('$API/api/notifications/read-all'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        return const DriverApiResult.success(null);
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DriverApiResult.failure(DriverApiError.unauthorized);
      }

      return const DriverApiResult.failure(
        DriverApiError.server,
        message: 'Could not mark all notifications read.',
      );
    } catch (_) {
      return const DriverApiResult.failure(
        DriverApiError.network,
        message: 'Unable to reach the backend.',
      );
    }
  }

  static Future<DriverApiResult<DriverWallet>> fetchWallet(
    AuthService authService,
  ) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    try {

      final response = await http.get(
        Uri.parse('$API/api/wallet/driver/me'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return DriverApiResult.success(DriverWallet.fromJson(body));
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DriverApiResult.failure(DriverApiError.unauthorized);
      }

      return const DriverApiResult.failure(
        DriverApiError.server,
        message: 'Failed to load wallet.',
      );
    } catch (_) {
      return const DriverApiResult.failure(
        DriverApiError.network,
        message: 'Unable to reach the backend.',
      );
    }
  }

  static Future<DriverApiResult<List<WalletTransaction>>>
  fetchWalletTransactions(
    AuthService authService, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    try {
      final uri = Uri.parse(
        '$API/api/wallet/driver/me/transactions?page=$page&pageSize=$pageSize',
      );
      final response = await http.get(uri, headers: _headers(token));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (body['items'] as List<dynamic>?) ?? [];
        final transactions = items
            .cast<Map<String, dynamic>>()
            .map(WalletTransaction.fromJson)
            .toList();
        return DriverApiResult.success(transactions);
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DriverApiResult.failure(DriverApiError.unauthorized);
      }

      return const DriverApiResult.failure(
        DriverApiError.server,
        message: 'Failed to load wallet transactions.',
      );
    } catch (_) {
      return const DriverApiResult.failure(
        DriverApiError.network,
        message: 'Unable to reach the backend.',
      );
    }
  }

  static Future<DriverApiResult<void>> withdrawFunds(
    AuthService authService,
    double amount,
    String currency,
  ) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    try {
      final response = await http.post(
        Uri.parse('$API/api/wallet/driver/withdraw'),
        headers: _headers(token),
        body: jsonEncode({'amount': amount, 'currency': currency}),
      );

      if (response.statusCode == 200) {
        return const DriverApiResult.success(null);
      }

      if (response.statusCode == 400) {
        return DriverApiResult.failure(
          DriverApiError.badRequest,
          message: _extractApiMessage(response.body),
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DriverApiResult.failure(DriverApiError.unauthorized);
      }

      return const DriverApiResult.failure(
        DriverApiError.server,
        message: 'Withdrawal request failed.',
      );
    } catch (_) {
      return const DriverApiResult.failure(
        DriverApiError.network,
        message: 'Unable to reach the backend.',
      );
    }
  }

  static Future<DriverApiResult<DriverProfile>> fetchDriverProfile(
    AuthService authService,
  ) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    final userResult = await UserService.getUserInfo(authService);
    if (!userResult.isSuccess) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    try {
      final driverResponse = await http.get(
        Uri.parse('$API/api/drivers/me'),
        headers: _headers(token),
      );

      if (driverResponse.statusCode != 200) {
        if (driverResponse.statusCode == 404) {
          return const DriverApiResult.failure(DriverApiError.notFound);
        }

        if (driverResponse.statusCode == 401 ||
            driverResponse.statusCode == 403) {
          return const DriverApiResult.failure(DriverApiError.unauthorized);
        }

        return DriverApiResult.failure(
          DriverApiError.server,
          message: 'Could not load driver profile.',
        );
      }

      final driverJson =
          jsonDecode(driverResponse.body) as Map<String, dynamic>;
      Map<String, dynamic>? reviewsJson;
      Map<String, dynamic>? missionsJson;

      try {
        final reviewsResponse = await http.get(
          Uri.parse(
            '$API/api/drivers/${driverJson['driverId']}/reviews?page=1&pageSize=1',
          ),
          headers: _headers(token),
        );
        if (reviewsResponse.statusCode == 200) {
          reviewsJson =
              jsonDecode(reviewsResponse.body) as Map<String, dynamic>;
        }
      } catch (_) {
        reviewsJson = null;
      }

      try {
        final missionsResponse = await http.get(
          Uri.parse('$API/api/deliveries/my-missions?page=1&pageSize=1'),
          headers: _headers(token),
        );

        if (missionsResponse.statusCode == 200) {
          missionsJson =
              jsonDecode(missionsResponse.body) as Map<String, dynamic>;
        }
      } catch (_) {
        missionsJson = null;
      }

      final profile = DriverProfile.fromJson(
        userResult.data!,
        driverJson,
        reviewsJson: reviewsJson,
        missionsJson: missionsJson,
      );
      return DriverApiResult.success(profile);
    } catch (_) {
      return const DriverApiResult.failure(
        DriverApiError.network,
        message: 'Unable to reach the backend.',
      );
    }
  }

  static Future<DriverApiResult<DriverProfile>> updateDriverProfile(
    AuthService authService,
    String firstName,
    String lastName,
    String phone,
  ) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    try {
      final response = await http.patch(
        Uri.parse('$API/api/users/me'),
        headers: _headers(token),
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        return fetchDriverProfile(authService);
      }

      if (response.statusCode == 400) {
        return DriverApiResult.failure(
          DriverApiError.badRequest,
          message: _extractApiMessage(response.body),
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DriverApiResult.failure(DriverApiError.unauthorized);
      }

      return const DriverApiResult.failure(
        DriverApiError.server,
        message: 'Could not update profile.',
      );
    } catch (_) {
      return const DriverApiResult.failure(
        DriverApiError.network,
        message: 'Unable to reach the backend.',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // MISSION STATUS & HISTORY MANAGEMENT
  // ─────────────────────────────────────────────────────────────────

  /// Fetch detailed mission information with complete status history
  static Future<DriverApiResult<DriverMission>> fetchMissionDetails(
    AuthService authService,
    String deliveryId,
  ) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    try {
      final uri = Uri.parse('$API/api/deliveries/$deliveryId');
      final response = await http.get(uri, headers: _headers(token));

      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final mission = DriverMission.fromJson(body);
        return DriverApiResult.success(mission);
      }

      if (response.statusCode == 404) {
        return const DriverApiResult.failure(DriverApiError.notFound);
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DriverApiResult.failure(DriverApiError.unauthorized);
      }

      return DriverApiResult.failure(
        DriverApiError.server,
        message: 'Failed to load mission details.',
      );
    } catch (_) {
      return const DriverApiResult.failure(
        DriverApiError.network,
        message: 'Unable to reach the backend.',
      );
    }
  }

  /// Update mission status to the backend
  /// Valid transitions: ACCEPTED → ARRIVED_AT_PICKUP → PICKED_UP → IN_TRANSIT → ARRIVED_AT_DROPOFF → DELIVERED
  static Future<DriverApiResult<String>> updateMissionStatus(
    AuthService authService,
    String deliveryId,
    String newStatus, {
    String? note,
  }) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    try {
      final body = {'newStatus': newStatus, if (note != null) 'note': note};

      final response = await http.patch(
        Uri.parse('$API/api/deliveries/$deliveryId/status'),
        headers: _headers(token),
        body: jsonEncode(body),
      );

      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final status = responseBody['status']?.toString() ?? newStatus;
        return DriverApiResult.success(status);
      }

      if (response.statusCode == 400) {
        return DriverApiResult.failure(
          DriverApiError.badRequest,
          message: _extractApiMessage(response.body),
        );
      }

      if (response.statusCode == 404) {
        return const DriverApiResult.failure(DriverApiError.notFound);
      }

      if (response.statusCode == 409) {
        return DriverApiResult.failure(
          DriverApiError.conflict,
          message: _extractApiMessage(response.body),
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DriverApiResult.failure(DriverApiError.unauthorized);
      }

      return DriverApiResult.failure(
        DriverApiError.server,
        message: 'Could not update mission status.',
      );
    } catch (e) {
      print('Error updating mission status: $e');
      return const DriverApiResult.failure(
        DriverApiError.network,
        message: 'Unable to reach the backend.',
      );
    }
  }

  /// Get mission history with pagination
  static Future<DriverApiResult<List<DriverMission>>> fetchMissionHistory(
    AuthService authService, {
    int page = 1,
    int pageSize = _defaultPageSize,
  }) async {
    final token = await authService.getAccessToken();
    if (token == null) {
      return const DriverApiResult.failure(DriverApiError.unauthorized);
    }

    try {
      final uri = Uri.parse(
        '$API/api/deliveries/my-missions/history?page=$page&pageSize=$pageSize',
      );
      final response = await http.get(uri, headers: _headers(token));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (body['items'] as List<dynamic>?) ?? [];
        final missions = items
            .cast<Map<String, dynamic>>()
            .map(DriverMission.fromJson)
            .toList();
        return DriverApiResult.success(missions);
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const DriverApiResult.failure(DriverApiError.unauthorized);
      }

      return DriverApiResult.failure(
        DriverApiError.server,
        message: 'Failed to load mission history.',
      );
    } catch (_) {
      return const DriverApiResult.failure(
        DriverApiError.network,
        message: 'Unable to reach the backend.',
      );
    }
  }

  static String? _extractApiMessage(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        return json['message']?.toString();
      }
    } catch (_) {
      // ignore
    }
    return null;
  }
}
