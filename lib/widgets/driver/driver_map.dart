import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wasel/themes/colors.dart';

// Simple, reusable map widget using OpenStreetMap via flutter_map.
// - center: initial center
// - markers: optional markers to show
// - polylinePoints: optional polyline for route
class DriverMap extends StatelessWidget {
  final LatLng center;
  final List<Marker> markers;
  final List<LatLng>? polylinePoints;
  final double height;

  const DriverMap({
    super.key,
    required this.center,
    this.markers = const [],
    this.polylinePoints,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 13),
          children: [
  TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.example.wasel',
    tileProvider: NetworkTileProvider(),
  ),

  if (polylinePoints != null && polylinePoints!.isNotEmpty)
  PolylineLayer(
    polylines: [
      Polyline(
        points: polylinePoints!,
        strokeWidth: 5,
        color: primaryColor,
      ),
    ],
  ),

  if (markers.isNotEmpty)
    MarkerLayer(markers: markers),
],
        ),
      ),
    );
  }
}
