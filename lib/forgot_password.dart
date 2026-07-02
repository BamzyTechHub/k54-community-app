import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() =>
      _ForgotPasswordState();
}

class _ForgotPasswordState
    extends State<ForgotPassword> {
final TextEditingController emailController =
    TextEditingController();

final AuthService authService =
    AuthService();

@override
void dispose() {
  emailController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
     return Scaffold(
  resizeToAvoidBottomInset: true,
  backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),

          child: SingleChildScrollView(
  child: Column(
  mainAxisSize: MainAxisSize.min,
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
                "Forgot Password",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 12),

              // Description
              const Text(
                "Enter your email below to receive your password reset instructions",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 35),

              // Email Field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: "Enter Email",

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFFDAD7D7),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Send Password Button
                 GestureDetector(
  onTap: () async {

    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter your email"),
        ),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password reset email sent",
          ),
        ),
      );

    } on FirebaseAuthException catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? "Failed to send email",
          ),
        ),
      );
    }
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
        "Send Password",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
),

              const SizedBox(height: 25),

              // Remember Password
               GestureDetector(
  onTap: () {
    Navigator.pop(context);
  },
  child: const Text(
    "I remember the password",
    style: TextStyle(
      color: Colors.green,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  ),
),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
    );
  }
}