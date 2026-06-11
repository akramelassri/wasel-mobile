import 'package:wasel/model/driver_mission_model.dart';

// ─────────────────────────────────────────────────────────────────
// MODÈLE LOCAL — représente une course disponible retournée par
// GET /api/deliveries/available.
// ─────────────────────────────────────────────────────────────────
class AvailableDelivery {
  final String id;
  final String pickupLabel;
  final String dropoffLabel;
  final double distanceKm;
  final double price;
  final double weightKg;
  final bool isFragile;
  final String status;
  final double pickupLatitude;
  final double pickupLongitude;

  final double dropoffLatitude;
  final double dropoffLongitude;

  const AvailableDelivery({
    required this.id,
    required this.pickupLabel,
    required this.dropoffLabel,
    required this.distanceKm,
    required this.price,
    required this.weightKg,
    required this.isFragile,
    required this.status,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
  });

  factory AvailableDelivery.fromJson(Map<String, dynamic> json) {
    final pickup = json['pickupAddress'] as Map<String, dynamic>;
    final dropoff = json['dropoffAddress'] as Map<String, dynamic>;
  
    final pickupStreet = pickup['street'] as String? ?? '';
    final pickupCity = pickup['city'] as String? ?? '';
  
    final dropoffStreet = dropoff['street'] as String? ?? '';
    final dropoffCity = dropoff['city'] as String? ?? '';
    
    
  
    return AvailableDelivery(
      id: json['id'].toString(),
  
      pickupLabel: [
        pickupStreet,
        pickupCity,
      ].where((e) => e.isNotEmpty).join(', '),
  
      dropoffLabel: [
        dropoffStreet,
        dropoffCity,
      ].where((e) => e.isNotEmpty).join(', '),
  
      distanceKm: (json['estimatedDistanceKm'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      weightKg: (json['weight'] as num?)?.toDouble() ?? 0.0,
      isFragile: json['isFragile'] as bool? ?? false,
      status: json['status'] as String? ?? 'ACCEPTED',
      pickupLatitude:
      (pickup['latitude'] as num?)?.toDouble() ?? 0,

      pickupLongitude:
          (pickup['longitude'] as num?)?.toDouble() ?? 0,

      dropoffLatitude:
          (dropoff['latitude'] as num?)?.toDouble() ?? 0,

      dropoffLongitude:
          (dropoff['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  factory AvailableDelivery.fromDriverMission(DriverMission mission) {
    return AvailableDelivery(
      id: mission.id,
      pickupLabel: mission.pickupLabel,
      dropoffLabel: mission.dropoffLabel,
      distanceKm: 0.0,
      price: mission.earnedAmount,
      weightKg: 0.0,
      isFragile: false,
      status: mission.status,
      pickupLatitude: mission.pickupLatitude,
      pickupLongitude: mission.pickupLongitude,
      dropoffLatitude: mission.dropoffLatitude,
      dropoffLongitude: mission.dropoffLongitude,
    );
  }
}
