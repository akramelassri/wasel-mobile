import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Note: reverse geocoding uses Nominatim (no API key needed), not a Wasel endpoint

class LocationService {
  static const _timeout = Duration(seconds: 10);

  // ── current position ───────────────────────────────────────────

  Future<Position?> getCurrentPosition() async {
    final permission = await _ensurePermission();
    if (!permission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _ensurePermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      return true;
    } catch (_) {
      // Catch PlatformExceptions from custom/locked-down Android OS variants
      return false;
    }
  }

  // ── reverse geocoding ──────────────────────────────────────────

  Future<AddressResult?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
      );
      final response = await http
          .get(
            uri,
            headers: {
              'Accept-Language': 'en',
              // FIX 1: Comply with Nominatim policy to avoid 403 Forbidden blocks
              'User-Agent': 'com.example.wasel (dynn0s123@gmail.com)',
            },
          )
          .timeout(_timeout); // Added 10-second timeout

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);

      // APPLIED FIX: Safe fallback if clicked in unmapped areas/ocean
      if (data['error'] != null) return null;

      final address = data['address'] as Map<String, dynamic>?;
      final displayName =
          (data['display_name']?.toString() ?? 'Unknown location');

      if (address == null) {
        // Fallback for unmapped coordinates that still return a display name
        return AddressResult(
          label: displayName,
          street: '',
          city: '',
          postalCode: '',
          country: 'Morocco',
          latitude: lat,
          longitude: lng,
        );
      }

      // FIX 2: Safely convert everything to String, as OSM sometimes returns numbers
      return AddressResult(
        label: displayName,
        street: _buildStreet(address),
        city:
            (address['city']?.toString() ??
            address['town']?.toString() ??
            address['village']?.toString() ??
            ''),
        postalCode: address['postcode']?.toString() ?? '',
        country: address['country']?.toString() ?? 'Morocco',
        latitude: lat,
        longitude: lng,
      );
    } catch (_) {
      return null;
    }
  }

  String _buildStreet(Map<String, dynamic> address) {
    final road = address['road']?.toString() ?? '';
    final houseNumber = address['house_number']?.toString() ?? '';
    if (houseNumber.isNotEmpty) return '$houseNumber $road';
    return road;
  }
}

class AddressResult {
  final String label;
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final double latitude;
  final double longitude;

  const AddressResult({
    required this.label,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  String _truncate(String text, int maxLength) {
    if (text.isEmpty) return '';
    return text.length > maxLength ? text.substring(0, maxLength) : text;
  }

  // Inside LocationService.dart -> AddressResult class at the bottom
  Map<String, dynamic> toJson() {
    final safeLabel = label.trim().isEmpty ? 'Selected Location' : label.trim();
    final safeStreet = street.trim().isEmpty
        ? 'Street Not Specified'
        : street.trim();
    final safeCity = city.trim().isEmpty ? 'City Not Specified' : city.trim();
    final safeCountry = country.trim().isEmpty ? 'Morocco' : country.trim();
    final safePostal = postalCode.trim().isEmpty ? '00000' : postalCode.trim();

    return {
      // ✅ Truncated to 90 chars to safely fit inside PostgreSQL VARCHAR(100)
      'label': _truncate(safeLabel, 90),
      'street': _truncate(safeStreet, 90),
      'city': _truncate(safeCity, 90),
      'country': _truncate(safeCountry, 90),
      'postalCode': _truncate(safePostal, 20),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
