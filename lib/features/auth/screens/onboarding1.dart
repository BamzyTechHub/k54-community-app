import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/features/auth/screens/onboarding4.dart';

class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

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

                        decoration: const BoxDecoration(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10)),
                          // Solid brand green, not the old green-to-gold
                          // gradient - matches the button below it and
                          // every other brand accent app-wide (flagged by
                          // tester feedback: onboarding colors weren't
                          // consistent with the rest of the app).
                          color: AppColors.green,
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
        builder: (context) => const Onboarding4(),
      ),
    );
  },

  child: Container(
    width: 60,
    height: 60,

    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      border: Border.fromBorderSide(
        BorderSide(color: AppColors.green, width: 3),
      ),
    ),

    child: Center(
      child: Container(
        width: 42,
        height: 42,

        // Solid brand green, not the old green-to-gold gradient - matches
        // the app's real button color language (PrimaryButton, indicator
        // above) instead of a one-off treatment unique to this screen.
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.green,
        ),

        child: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.white,
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
