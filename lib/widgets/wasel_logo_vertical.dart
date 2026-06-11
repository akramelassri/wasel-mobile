import 'package:flutter/material.dart';
import 'package:wasel/widgets/wasel_logo.dart';
import 'package:wasel/themes/text_styles.dart';

class WaselLogoVertical extends StatelessWidget {
  const WaselLogoVertical({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WaselLogo(width: 128, height: 64),
        Text('Wasel', style: headingText),
      ],
    );
  }
}
