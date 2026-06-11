import 'package:flutter/material.dart';
import 'package:wasel/themes/text_styles.dart';

// ─────────────────────────────────────────────────────────────────
// WIDGET LIGNE D'ADRESSE
// Réutilisé pour pickup et dropoff — évite la répétition de code
// ─────────────────────────────────────────────────────────────────
class AddressRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const AddressRow({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: bodyText.copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
