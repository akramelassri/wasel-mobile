import 'package:flutter/material.dart';
import 'package:wasel/main.dart';
import 'package:wasel/screens/main_screen.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';
import 'package:wasel/widgets/wasel_logo_horizontal.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isAuthenticating = false;

  void _navigateHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  Future<void> _handleAuth(bool isLogin) async {
    // Prevent double-taps
    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);
    final authService = InheritedAuth.of(context).authService;

    // AuthService returns true on success, false on cancel/error
    final success = isLogin
        ? await authService.login()
        : await authService.register();

    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    if (success) {
      _navigateHome();
    }
    // Note: We don't show a snackbar on false because 'false' usually just
    // means the user pressed the back button to close the Keycloak webview.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const WaselLogoHorizontal(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 32),
                child: Image.asset(
                  'assets/welcome-image.png',
                  fit: BoxFit.contain,
                  height: 260,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Move anything\nin minutes',
                textAlign: TextAlign.center,
                style: displayText.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 12),
              Opacity(
                opacity: 0.5,
                child: Text(
                  'Reliable, fast, and secure delivery across the city. Just tap and track.',
                  textAlign: TextAlign.center,
                  style: labelText,
                ),
              ),
              const SizedBox(height: 40),

              // ── Register Button ──────────────────────────────────────────
              ElevatedButton(
                onPressed: _isAuthenticating ? null : () => _handleAuth(false),
                style: ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 14),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled))
                      return primaryColor.withValues(alpha: 0.5);
                    return primaryColor;
                  }),
                  foregroundColor: const WidgetStatePropertyAll(onPrimary),
                  textStyle: WidgetStatePropertyAll(bolderLabelText),
                ),
                child: _isAuthenticating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Join now'),
              ),
              const SizedBox(height: 12),

              // ── Login Button ─────────────────────────────────────────────
              ElevatedButton(
                onPressed: _isAuthenticating ? null : () => _handleAuth(true),
                style: ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: _isAuthenticating
                            ? Colors.transparent
                            : primaryColorw600,
                      ),
                    ),
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 14),
                  ),
                  backgroundColor: const WidgetStatePropertyAll(surfaceColor),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled))
                      return Colors.black38;
                    return onSurface;
                  }),
                  textStyle: WidgetStatePropertyAll(bolderLabelText),
                ),
                child: const Text('Sign in'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
