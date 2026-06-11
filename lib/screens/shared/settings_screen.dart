import 'package:flutter/material.dart';
import 'package:wasel/main.dart';
import 'package:wasel/screens/welcome_screen.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';
import 'package:wasel/screens/driver/profile_screen.dart';
import 'package:wasel/screens/driver/wallet_screen.dart';

class SettingsScreen extends StatelessWidget {
  final bool isDriver;
  final VoidCallback onModeSwitch;

  const SettingsScreen({
    super.key,
    required this.isDriver,
    required this.onModeSwitch,
  });

  @override
  Widget build(BuildContext context) {
    final authService = InheritedAuth.of(context).authService;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const Icon(Icons.person_rounded, color: secondaryColor),
                title: Text('My Profile', style: labelText),
                trailing: const Icon(Icons.chevron_right_rounded, color: secondaryColor),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_rounded, color: secondaryColor),
                title: Text('My Wallet', style: labelText),
                trailing: const Icon(Icons.chevron_right_rounded, color: secondaryColor),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverWalletScreen()),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onModeSwitch,
                icon: Icon(
                  isDriver ? Icons.person_rounded : Icons.drive_eta_rounded,
                  color: secondaryColor,
                ),
                label: Text(
                  isDriver ? 'Switch to Client Mode' : 'Switch to Driver Mode',
                  style: bolderLabelText.copyWith(color: secondaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: surfaceVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await authService.clearTokens();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: Text(
                  'Logout',
                  style: bolderLabelText.copyWith(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
