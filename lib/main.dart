import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:wasel/api/auth_service.dart';
import 'package:wasel/screens/splash_screen.dart';

void main() {
  // 1. Ensure widgets are bound first
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 2. Tell the OS to keep the native splash screen on screen!
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return InheritedAuth(
      authService: AuthService(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}

class InheritedAuth extends InheritedWidget {
  final AuthService authService;

  const InheritedAuth({
    super.key,
    required this.authService,
    required super.child,
  });

  static InheritedAuth of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedAuth>()!;
  }

  @override
  bool updateShouldNotify(InheritedAuth oldWidget) => false;
}
