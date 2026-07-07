import 'package:flutter/material.dart';
import 'package:k54_mobile/features/auth/screens/login.dart';

//  import 'home.dart'; // Replace with your actual home screen

class Onboarding4 extends StatelessWidget {
  const Onboarding4({super.key});

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
              GestureDetector(
                onTap: () {
                  // Change this to your home screen
                  Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => const Login(),
  ),
);
                },

                child: Container(
                  width: double.infinity,
                  height: 55,

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),

                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF008000),
                        Color(0xFFAB8000),
                        Color(0xFF008000),
                      ],
                    ),
                  ),

                  child: const Center(
                    child: Text(
                      "Jump In!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
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