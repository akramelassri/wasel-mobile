import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:wasel/main.dart';
import 'package:wasel/screens/main_screen.dart';
import 'package:wasel/screens/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // We wait for the first frame, then fire the auth check
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  Future<void> _checkAuth() async {
    final authService = InheritedAuth.of(context).authService;
    final isAuthenticated = await authService.isAuthenticated();

    if (!mounted) return;

    // 🚨 3. REMOVE THE NATIVE SPLASH SCREEN RIGHT BEFORE WE ROUTE
    FlutterNativeSplash.remove();

    if (isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // You don't even need a spinner anymore!
    // The native OS splash screen covers this completely until remove() is called.
    return const Scaffold(
      backgroundColor:
          Colors.white, // Match your flutter_native_splash.yaml color
    );
  }
}
