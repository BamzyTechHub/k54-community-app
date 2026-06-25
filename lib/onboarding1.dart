import 'package:flutter/material.dart';
import 'onboarding2.dart';

class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

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
                width: 100,
              ),

              const SizedBox(height: 35),

              // Illustration
              Image.asset(
                "assets/images/onboarding1.png",
                width: 300,
              ),

              const SizedBox(height: 30),

              // Text
              const Text(
                "Connect, Collaborate and\nCommunicate!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFF505050),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const Spacer(),

              // Bottom navigation
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [

                  // Indicator
                  Row(
                    children: [

                      Container(
                        width: 28,
                        height: 8,

                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(10),

                          gradient:
                              const LinearGradient(
                            colors: [
                              Color(0xFF008000),
                              Color(0xFFAB8000),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        width: 8,
                        height: 8,

                        decoration: const BoxDecoration(
                          color: Color(0xFFDAD7D7),
                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        width: 8,
                        height: 8,

                        decoration: const BoxDecoration(
                          color: Color(0xFFDAD7D7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),


                  // Next button
                 GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Onboarding2(),
      ),
    );
  },

  child: Container(
    width: 60,
    height: 60,

    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: const Color(0xFF578C77),
        width: 3,
      ),
    ),

    child: Center(
      child: Container(
        width: 42,
        height: 42,

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
          size: 18,
        ),
      ),
    ),
  ),
)
                ],
              ),

              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }
}