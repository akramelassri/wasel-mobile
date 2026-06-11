import 'package:flutter/material.dart';
import 'package:wasel/api/auth_service.dart';
import 'package:wasel/main.dart';
import 'package:wasel/screens/client/home_screen.dart';
import 'package:wasel/screens/client/requests_screen.dart';
import 'package:wasel/screens/driver/home_screen.dart';
import 'package:wasel/screens/driver/requests_screen.dart';
import 'package:wasel/screens/shared/settings_screen.dart';
import 'package:wasel/widgets/wasel_bottom_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isDriver = false;
  bool _loading = true;
  bool _isSwitchingMode =
      false; // Added to prevent double-clicks during API call

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMode());
  }

  Future<void> _loadMode() async {
    final authService = InheritedAuth.of(context).authService;
    final mode = await authService.getMode();
    if (!context.mounted) return;
    setState(() {
      _isDriver = mode == UserMode.driver;
      _loading = false;
    });
  }

  Future<void> _switchMode() async {
    if (_isSwitchingMode) return; // Guard against multiple taps

    setState(() {
      _isSwitchingMode = true;
    });

    try {
      final authService = InheritedAuth.of(context).authService;
      final targetIsDriver = !_isDriver;

      // 1. Fire the request to the C# Backend
      final success = await authService.switchAppMode(targetIsDriver);

      if (success) {
        // 2. Update local secure storage
        final newMode = targetIsDriver ? UserMode.driver : UserMode.client;
        await authService.setMode(newMode);

        // 3. Update UI and jump back to the Home tab
        if (mounted) {
          setState(() {
            _isDriver = targetIsDriver;
            _currentIndex = 0;
          });
        }
      } else {
        // 4. Handle API Failure
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to switch modes. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSwitchingMode = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = [
      _isDriver ? const DriverHomeScreen() : const ClientHomeScreen(),
      _isDriver ? const DriverRequestsScreen() : const ClientRequestsScreen(),
      // You can pass _isSwitchingMode down here if you want to show a spinner on the button!
      SettingsScreen(isDriver: _isDriver, onModeSwitch: _switchMode),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: WaselBottomBar(
        currentIndex: _currentIndex,
        onTabSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
