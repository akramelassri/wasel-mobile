class DriverProfile {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String? profileImageUrl;
  final double averageRating;
  final int totalMissions;
  final String vehicleType;
  final String vehicleMatricule;

  const DriverProfile({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    this.profileImageUrl,
    required this.averageRating,
    required this.totalMissions,
    required this.vehicleType,
    required this.vehicleMatricule,
  });

  String get fullName => '$firstName $lastName';

  factory DriverProfile.fromJson(
    Map<String, dynamic> userJson,
    Map<String, dynamic> driverJson, {
    Map<String, dynamic>? reviewsJson,
    Map<String, dynamic>? missionsJson,
  }) {
    final vehicle = driverJson['vehicle'] as Map<String, dynamic>?;
    final profileObjectKey = userJson['profileObjectKey'] as String?;

    return DriverProfile(
      firstName: userJson['firstName'] as String? ?? '',
      lastName: userJson['lastName'] as String? ?? '',
      phone: userJson['phone'] as String? ?? '',
      email: userJson['email'] as String? ?? '',
      profileImageUrl: profileObjectKey != null && profileObjectKey.isNotEmpty
          ? profileObjectKey
          : null,
      averageRating: (reviewsJson?['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalMissions: missionsJson?['totalItems'] as int? ?? 0,
      vehicleType: vehicle?['type'] as String? ?? '',
      vehicleMatricule: vehicle?['matricule'] as String? ?? '',
    );
  }
}
