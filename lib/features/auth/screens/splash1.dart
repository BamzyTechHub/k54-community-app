import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/features/auth/screens/login.dart';
import 'package:k54_mobile/features/auth/screens/onboarding1.dart';
import 'package:k54_mobile/features/home/screens/home_page.dart';

const String hasSeenOnboardingKey = "hasSeenOnboarding";

/// Auth gate: returning users with a still-valid session skip straight to
/// Home, returning users who've seen onboarding before go straight to
/// Login, and only genuinely first-time users see the Splash/Onboarding
/// flow at all. Previously every launch hit Splash -> Onboarding
/// unconditionally regardless of session state - AuthService.isLoggedIn()
/// already existed but was never called anywhere.
class Splash1 extends StatefulWidget {
  const Splash1({super.key});

  @override
  State<Splash1> createState() => _Splash1State();
}

class _Splash1State extends State<Splash1> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final loggedIn = await AuthService().isLoggedIn();
    if (loggedIn) {
      try {
        // Confirms the stored token still actually works server-side,
        // not just that one is present locally.
        await AuthService().getCurrentUser();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
        return;
      } catch (_) {
        // Stored token is stale/expired - fall through to the normal flow.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool(hasSeenOnboardingKey) ?? false;
    if (seenOnboarding) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
        (route) => false,
      );
      return;
    }

    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.shrink(),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [

         // Top left gold glow
Positioned(
  top: -60,
  left: -90,
  child: Container(
    width: 420,
height: 420,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          Color(0x70AB8000),
          Colors.transparent,
        ],
      ),
    ),
  ),
),

// Top right green glow
Positioned(
  top: -140,
  right: -70,
  child: Container(
    width: 420,
height: 420,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          Color(0x606C9B6E),
          Colors.transparent,
        ],
      ),
    ),
  ),
),

// Bottom left gold glow
Positioned(
  bottom: -100,
  left: -90,
  child: Container(
    width: 420,
    height: 420,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          Color(0x40AB8000),
          Colors.transparent,
        ],
      ),
    ),
  ),
),

// Bottom right green glow
Positioned(
  bottom: -100,
  right: -70,
  child: Container(
    width: 420,
    height: 420,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          Color(0x55008000),
          Colors.transparent,
        ],
      ),
    ),
  ),
),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),

              child: Column(
                children: [

                  const SizedBox(height: 150),

                  // Logo
                  Image.asset(
                                "assets/images/k54_splash_logo.png",
                                width: 300,
                                fit: BoxFit.contain,
                              ), 

                  const SizedBox(height: 150),

                  // Text
                  const Text(
  "Your all-in-one site\nfor collaboration, productivity\nand growth",
  textAlign: TextAlign.center,
  style: TextStyle(
    fontSize: 20,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    height: 1.3,
  ),
),

                  const Spacer(),

                  // Proceed button
                 SizedBox(
  width: double.infinity,
  height: 55,

  child: GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Onboarding1(),
        ),
      );
    },

    child: Container(
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
),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}