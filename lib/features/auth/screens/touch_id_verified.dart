import 'package:flutter/material.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/features/home/screens/home_page.dart';

/// Only ever reached from touch_id.dart, which now only lets this happen
/// when a valid stored session already exists - so "verified" here means
/// "unlocked an existing session," not "just signed up." Goes straight to
/// Home (previously incorrectly routed to ProfileSetup, the brand-new-
/// signup flow, every time).
class TouchIdVerified extends StatelessWidget {
  const TouchIdVerified({super.key});

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

              const SizedBox(height: 30),

              // Title
              const Text(
                "Touch ID",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 10),

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

              const Spacer(),

              // Verified fingerprint
              Image.asset(
                "assets/images/fingerprint_verified.png",
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 20),

              // Verified text
              const Text(
                "Verified",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              // Proceed button
              PrimaryButton(
                label: "Proceed",
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 40),

            ],
          ),
        ),
      ),
    );
  }
}