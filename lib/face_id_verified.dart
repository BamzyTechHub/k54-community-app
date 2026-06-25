import 'package:flutter/material.dart';
import 'profile_setup.dart';

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
              GestureDetector(
  onTap: () {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileSetup(),
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
        "Proceed",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
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