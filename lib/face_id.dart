import 'package:flutter/material.dart';
import 'face_id_verified.dart';

class FaceId extends StatelessWidget {
  const FaceId({super.key});

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

              // Face ID Image
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FaceIdVerified(),
                    ),
                  );
                },

                child: Image.asset(
                  "assets/images/face_id_gray.png",
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