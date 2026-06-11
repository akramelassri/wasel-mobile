import 'package:flutter/material.dart';
import 'package:wasel/themes/text_styles.dart';
import 'package:wasel/widgets/wasel_logo.dart';

class WaselLogoHorizontal extends StatelessWidget {
  const WaselLogoHorizontal({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        WaselLogo(width: 64, height: 64),
        Text('Wasel', style: headingText),
      ],
    );
  }
}
