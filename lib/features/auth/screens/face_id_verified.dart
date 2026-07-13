import 'package:flutter/material.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/features/home/screens/home_page.dart';

/// Same reasoning as touch_id_verified.dart.
class FaceIdVerified extends StatelessWidget {
  const FaceIdVerified({super.key});

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
                "Face ID",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 15),

              // Description
              const Text(
                "Please look at the camera to authenticate your\nidentity.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 90),

              // Verified Face Image
              Image.asset(
                "assets/images/face_id_verified.png",
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 15),

              const Text(
                "Verified",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),

              const Spacer(),

              // Proceed Button
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