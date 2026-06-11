class StatusHistoryItem {
  final String status;
  final DateTime changedAt;
  final String? note;

  const StatusHistoryItem({
    required this.status,
    required this.changedAt,
    this.note,
  });

  factory StatusHistoryItem.fromJson(Map<String, dynamic> json) {
    return StatusHistoryItem(
      status:
          json['deliveryStatus']?.toString() ??
          json['status']?.toString() ??
          'UNKNOWN',
      changedAt:
          DateTime.tryParse(json['changedAt']?.toString() ?? '') ??
          DateTime.now(),
      note: json['comment']?.toString() ?? json['note']?.toString(),
    );
  }
}

class DriverMission {
  final String id;
  final String pickupLabel;
  final String dropoffLabel;
  final String status;
  final double earnedAmount;
  final DateTime date;
  final List<StatusHistoryItem> statusHistory;
  final DateTime? updatedAt;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;

  const DriverMission({
    required this.id,
    required this.pickupLabel,
    required this.dropoffLabel,
    required this.status,
    required this.earnedAmount,
    required this.date,
    this.statusHistory = const [],
    this.updatedAt,
    this.pickupLatitude = 0.0,   
    this.pickupLongitude = 0.0,
    this.dropoffLatitude = 0.0,
    this.dropoffLongitude = 0.0,
  });

  bool get isActive => status != 'DELIVERED' && !status.startsWith('CANCELLED');

  DriverMission copyWith({
    String? id,
    String? pickupLabel,
    String? dropoffLabel,
    String? status,
    double? earnedAmount,
    DateTime? date,
    List<StatusHistoryItem>? statusHistory,
    DateTime? updatedAt,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropoffLatitude,
    double? dropoffLongitude,
  }) {
    return DriverMission(
      id: id ?? this.id,
      pickupLabel: pickupLabel ?? this.pickupLabel,
      dropoffLabel: dropoffLabel ?? this.dropoffLabel,
      status: status ?? this.status,
      earnedAmount: earnedAmount ?? this.earnedAmount,
      date: date ?? this.date,
      statusHistory: statusHistory ?? this.statusHistory,
      updatedAt: updatedAt ?? this.updatedAt,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
      dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
    );
  }

  factory DriverMission.fromJson(Map<String, dynamic> json) {
    print("RAW MISSION JSON: $json");
  print("pickupAddress raw: ${json['pickupAddress']}");
  print("dropoffAddress raw: ${json['dropoffAddress']}");
    List<StatusHistoryItem> history = [];
    if (json['statusHistory'] is List) {
      history = (json['statusHistory'] as List)
          .cast<Map<String, dynamic>>()
          .map(StatusHistoryItem.fromJson)
          .toList();
    }

    final pickup = json['pickupAddress'];
    final dropoff = json['deliveryAddress'];

    String buildLabel(dynamic address) {
      if (address is Map<String, dynamic>) {
        final street = address['street']?.toString() ?? '';
        final city = address['city']?.toString() ?? '';
        return [street, city].where((e) => e.isNotEmpty).join(', ');
      }
      return address?.toString() ?? '';
    }

    double extractCoord(dynamic address, String field) {
      if (address is Map<String, dynamic>) {
        return (address[field] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    }

    return DriverMission(
      id: json['deliveryId']?.toString() ?? json['id']?.toString() ?? '',
      pickupLabel: buildLabel(pickup),
      dropoffLabel: buildLabel(dropoff?? json['dropoffAddress']),
      status:
          json['finalStatus']?.toString() ??
          json['deliveryStatus']?.toString() ??
          json['status']?.toString() ??
          'ACCEPTED',
      earnedAmount:
          (json['amountEarned'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0.0,
      date:
          DateTime.tryParse(
            json['date']?.toString() ??
                json['createdAt']?.toString() ??
                json['updatedAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      statusHistory: history,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),

      pickupLatitude: extractCoord(pickup, 'latitude'),
      pickupLongitude: extractCoord(pickup, 'longitude'),
      dropoffLatitude: extractCoord(dropoff, 'latitude'),
      dropoffLongitude: extractCoord(dropoff, 'longitude'),
    );
  }
}