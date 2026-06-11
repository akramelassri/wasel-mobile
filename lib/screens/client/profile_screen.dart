// lib/screens/client/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:wasel/api/user_service.dart';
import 'package:wasel/main.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userData; // Holds the parsed JSON from your service

  @override
  void initState() {
    super.initState();
    // Safe way to call InheritedAuth on init
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchProfile());
  }

  Future<void> _fetchProfile() async {
    final authService = InheritedAuth.of(context).authService;

    // Call your static service
    final result = await UserService.getUserInfo(authService);

    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      setState(() {
        _userData = result.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = _getErrorMessage(result.error);
        _isLoading = false;
      });
    }
  }

  // Maps your UserServiceError enum to a UI-friendly message
  String _getErrorMessage(UserServiceError? error) {
    switch (error) {
      case UserServiceError.unauthorized:
        return 'Session expired. Please log in again.';
      case UserServiceError.network:
        return 'Network error. Please check your internet connection.';
      case UserServiceError.server:
        return 'Server error. Please try again later.';
      default:
        return 'An unexpected error occurred.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: onSurface),
        title: Text('My Profile', style: headingText),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: bodyText.copyWith(color: Colors.red),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor:
                          surfaceVariant, // Changed to match your colors.dart
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Safely parse Keycloak / Backend JWT fields
                    Text(
                      '${_userData?['firstName'] ?? 'Client'} ${_userData?['lastName'] ?? ''}'
                          .trim(),
                      style: displayText.copyWith(
                        fontSize: 28,
                      ), // Adjusted to match your text_styles.dart
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userData?['email'] ?? 'No email provided',
                      style: bodyText.copyWith(
                        color: onSurface.withValues(alpha: 0.6),
                      ), // Adapted for your colors
                    ),
                    const SizedBox(height: 32),

                    // Example additional field block
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: surfaceVariant),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 16),
                          Text('Account Active', style: labelText),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
