import 'package:flutter/material.dart';

class WaselLogo extends StatelessWidget {
  const WaselLogo({required this.width, required this.height, super.key});

  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/wasel-logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
