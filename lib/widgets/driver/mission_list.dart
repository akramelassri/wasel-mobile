import 'package:flutter/material.dart';
import 'package:wasel/model/driver_mission_model.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';
import 'package:wasel/widgets/driver/mission_card.dart';

// ─────────────────────────────────────────────────────────────────
// LISTE DE MISSIONS — réutilisée pour les deux onglets
// Reçoit la liste filtrée, évite de dupliquer le code d'affichage
// ─────────────────────────────────────────────────────────────────
class MissionList extends StatelessWidget {
  final List<DriverMission> missions;
  final String emptyMessage;
  final String emptySubMessage;
  final IconData emptyIcon;
  final void Function(DriverMission)? onMissionTap;

  const MissionList({
    required this.missions,
    required this.emptyMessage,
    required this.emptySubMessage,
    required this.emptyIcon,
    this.onMissionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 56, color: surfaceVariant),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: subHeadingText.copyWith(color: secondaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubMessage,
              style: captionText.copyWith(
                color: secondaryColor.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: missions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => MissionCard(
        mission: missions[index],
        onTap: onMissionTap == null
            ? null
            : () => onMissionTap!(missions[index]),
      ),
    );
  }
}
