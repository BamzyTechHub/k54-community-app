import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/features/auth/screens/signup.dart';
import 'package:k54_mobile/features/auth/screens/splash1.dart';

class Onboarding4 extends StatelessWidget {
  const Onboarding4({super.key});

  Future<void> _finishOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(hasSeenOnboardingKey, true);
    if (!context.mounted) return;
    // New users go Onboarding -> Sign Up (not Login), and the whole
    // Splash/Onboarding stack is cleared so a later back button on any
    // screen reached from here can never land back on onboarding.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignUp()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),

          child: Column(
            children: [

              const SizedBox(height: 20),

              // Logo
              Image.asset(
                "assets/images/k54_logo.png",
                width: 120,
              ),

              const SizedBox(height: 40),

              // Illustration
              Image.asset(
                "assets/images/onboarding4.png",
                width: 350,
                height: 280,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 25),

              // Text
              const Text(
                "You're about to experience collaboration\nlike never before. Let's get started!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const Spacer(),

              // Jump In Button
              PrimaryButton(
                label: "Jump In!",
                onPressed: () => _finishOnboarding(context),
              ),

              const SizedBox(height: 20),

              // Go Back Button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },

                child: Container(
                  width: double.infinity,
                  height: 55,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),

                    border: Border.all(
                      color: const Color(0xFFDAD7D7),
                    ),
                  ),

                  child: const Center(
                    child: Text(
                      "Go Back",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}