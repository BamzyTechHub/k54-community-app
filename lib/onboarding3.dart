import 'package:flutter/material.dart';
import 'onboarding4.dart';

class Onboarding3 extends StatelessWidget {
  const Onboarding3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),

          child: Column(
            children: [

              const SizedBox(height: 10),

              // Logo
              Image.asset(
                "assets/images/k54_logo.png",
                width: 94,
                height: 44,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 35),

              // Illustration
              Image.asset(
                "assets/images/onboarding3.png",
                width: 320,
                height: 250,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 45),

              // Description
              const Text(
                 "Jump in & make waves! Setup takes\nseconds.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF505050),
                ),
              ),

              const Spacer(),

              // Bottom navigation
              Row(
                children: [

                  // Indicators
                  Row(
                    children: [
                      _indicator(),
                      const SizedBox(width: 8),
                      _indicator(),
                      const SizedBox(width: 8),
                      _activeIndicator(),
                    ],
                  ),

                  const Spacer(),

                  // Finish button
                  GestureDetector(
                    onTap: () {
                      // Navigate to Login/Home screen
                      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const Onboarding4(),
  ),
);
                    },

                    child: Container(
                      height: 58,
                      width: 58,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF578C77),
                          width: 3,
                        ),
                      ),

                      child: Container(
                        margin: const EdgeInsets.all(7),

                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF008000),
                              Color(0xFFAB8000),
                            ],
                          ),
                        ),

                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }


  static Widget _indicator() {
    return Container(
      width: 8,
      height: 8,

      decoration: const BoxDecoration(
        color: Color(0xFFDAD7D7),
        shape: BoxShape.circle,
      ),
    );
  }


  static Widget _activeIndicator() {
    return Container(
      width: 30,
      height: 8,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),

        gradient: const LinearGradient(
          colors: [
            Color(0xFF008000),
            Color(0xFFAB8000),
          ],
        ),
      ),
    );
  }
}