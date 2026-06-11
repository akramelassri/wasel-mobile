import 'package:flutter/material.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';

// ─────────────────────────────────────────────────────────────────
// BADGE DE STATUT — couleur différente selon le statut
// Centralise la logique de couleur pour ne pas la répéter
// ─────────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({required this.status});

  // Mapping statut API → label lisible + couleur
  ({String label}) get _config => switch (status) {
    'ASSIGNED' => (
      label: 'Assigned',
    ),
    'ACCEPTED' => (
      label: 'Accepted',
    ),
    'ARRIVED_AT_PICKUP' => (
      label: 'At pickup',
    ),
    'PICKED_UP' => (
      label: 'Collected',
    ),
    'IN_TRANSIT' => (
      label: 'On the way',
    ),
    'ARRIVED_AT_DROPOFF' => (
      label: 'At dropoff',
    ),
    'DELIVERED' => (
      label: 'Delivered',
    ),
    _ => (
      label: 'Cancelled',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: secondaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        cfg.label,
        style: captionText.copyWith(
          color: secondaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
