import 'package:flutter/material.dart';

// Les étapes dans l'ordre — chaque étape a un label de statut,
// un label de bouton pour passer à l'étape suivante, et une icône.
class MissionStep {
  final String statusLabel;
  final String buttonLabel;
  final IconData icon;
  const MissionStep({
    required this.statusLabel,
    required this.buttonLabel,
    required this.icon,
  });
}

const missionSteps = [
  MissionStep(
    statusLabel: 'Accepted',
    buttonLabel: "I'm at pickup",
    icon: Icons.check_circle_outline_rounded,
  ),
  MissionStep(
    statusLabel: 'Arrived at pickup',
    buttonLabel: 'Parcel collected',
    icon: Icons.storefront_rounded,
  ),
  MissionStep(
    statusLabel: 'Parcel collected',
    buttonLabel: 'On my way',
    icon: Icons.inventory_2_rounded,
  ),
  MissionStep(
    statusLabel: 'In transit',
    buttonLabel: "I'm at dropoff",
    icon: Icons.directions_bike_rounded,
  ),
  MissionStep(
    statusLabel: 'Arrived at dropoff',
    buttonLabel: 'Delivered ✓',
    icon: Icons.location_on_rounded,
  ),
];
