import 'package:flutter/material.dart';
import 'package:k54_mobile/core/services/biometric_service.dart';
import 'package:k54_mobile/features/auth/screens/touch_id_verified.dart';

class TouchId extends StatelessWidget {
  const TouchId({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

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
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 15),

              // Description
              const Text(
                "Place and hold your finger on the fingerprint\nreader",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 120),

              // Fingerprint
                GestureDetector(
  onTap: () async {

    final biometric = BiometricService();

    final success = await biometric.authenticate();

    if (success && context.mounted) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const TouchIdVerified(),
        ),
      );

    }

  },

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