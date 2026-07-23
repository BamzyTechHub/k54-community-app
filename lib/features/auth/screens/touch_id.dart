import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/services/biometric_service.dart';
import 'package:k54_mobile/features/auth/screens/touch_id_verified.dart';

/// Device biometrics (local_auth) only prove this is the phone's owner -
/// they don't obtain a K54 session on their own. This screen previously
/// treated biometric success as if it were a real login and always routed
/// to ProfileSetup (the brand-new-signup flow), even for a device that
/// had never logged in at all. It now only acts as a shortcut to unlock
/// an *already-stored, still-valid* session - otherwise it tells the user
/// to log in with a password first, same as any biometric-unlock pattern.
class TouchId extends StatelessWidget {
  const TouchId({super.key});

  Future<void> _authenticate(BuildContext context) async {
    final loggedIn = await AuthService().isLoggedIn();
    if (!loggedIn) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Log in with your password first to enable biometric login")),
      );
      return;
    }
    try {
      await AuthService().getCurrentUser();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your saved session has expired - please log in again")),
      );
      return;
    }

    final biometric = BiometricService();
    final success = await biometric.authenticate();
    if (success && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TouchIdVerified()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),

          child: Column(
            children: [

              const SizedBox(height: 25),

              // Logo
              Image.asset(
                "assets/images/k54_logo.png",
                width: 120,
              ),

              const SizedBox(height: 35),

              // Title
              const Text(
                "Touch ID",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),

              const SizedBox(height: 15),

              // Description
              const Text(
                "Place and hold your finger on the fingerprint\nreader",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.grey,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 120),

              // Fingerprint
                GestureDetector(
  onTap: () => _authenticate(context),

  child: Image.asset(
    "assets/images/fingerprint_gray.png",
    width: 220,
    height: 220,
    fit: BoxFit.contain,
  ),
),

            ],
          ),
        ),
      ),
    );
  }
}
