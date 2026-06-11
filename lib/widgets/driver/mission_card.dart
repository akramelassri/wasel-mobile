import 'package:flutter/material.dart';
import 'package:wasel/model/driver_mission_model.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';
import 'package:wasel/widgets/driver/address_row.dart';
import 'package:wasel/widgets/driver/status_badge.dart';

// ─────────────────────────────────────────────────────────────────
// CARTE D'UNE MISSION — affiche le résumé d'une mission
// Même style que les cards client dans les maquettes
// ─────────────────────────────────────────────────────────────────
class MissionCard extends StatelessWidget {
  final DriverMission mission;
  final VoidCallback? onTap;

  const MissionCard({required this.mission, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: secondaryColor.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ligne 1 : statut + montant gagné ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge de statut coloré selon l'état de la mission
                StatusBadge(status: mission.status),
                // Montant — 0 DH si annulée, montant en jaune si livrée ou active
                Text(
                  mission.earnedAmount > 0
                      ? '+${mission.earnedAmount.toStringAsFixed(0)} DH'
                      : '—',
                  style: bolderLabelText.copyWith(
                    color: mission.earnedAmount > 0
                        ? primaryColor
                        : secondaryColor.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Adresses ──
            AddressRow(
              icon: Icons.circle,
              iconColor: primaryColor,
              label: mission.pickupLabel,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(width: 1.5, height: 12, color: surfaceVariant),
            ),
            const SizedBox(height: 4),
            AddressRow(
              icon: Icons.location_on_rounded,
              iconColor: primaryColor,
              label: mission.dropoffLabel,
            ),

            const SizedBox(height: 10),

            // ── Date ──
            Text(
              _formatDate(mission.date),
              style: captionText.copyWith(
                color: secondaryColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Formate la date de façon lisible : "Today 10:42 AM" ou "23 May 2:30 PM"
  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final hour = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$min';

    if (isToday) return 'Today $timeStr';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} $timeStr';
  }
}
