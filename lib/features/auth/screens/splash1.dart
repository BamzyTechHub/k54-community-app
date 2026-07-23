import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
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
        backgroundColor: AppColors.white,
        body: SizedBox.shrink(),
      );
    }
    return Container(
      // Smooth diagonal cream-to-white gradient - matches the "splash 2"
      // Figma frame exactly. Was 4 separate blurred radial "glow" circles
      // positioned at the corners, which is a visually different effect
      // (soft spotlights vs. a flat diagonal wash) - replaced rather than
      // layered on top of, since Figma shows one smooth gradient, not glows.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCF8ED), AppColors.white],
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.transparent,

        body: Stack(
          children: [

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

                  // 20px, not 150 - in the "splash 2" Figma frame the
                  // wordmark and subtitle sit close together as one
                  // cohesive lockup, not separated by a huge gap.
                  const SizedBox(height: 20),

                  // Text
                  const Text(
  "Your all-in-one site\nfor collaboration, productivity\nand growth",
  textAlign: TextAlign.center,
  style: TextStyle(
    fontSize: 20,
    fontStyle: FontStyle.italic,
    // Was w600 - noticeably heavier than the other onboarding screens'
    // subtext (w400), direct tester feedback.
    fontWeight: FontWeight.w400,
    color: AppColors.black,
    height: 1.3,
  ),
),

                  const Spacer(),

                  // Proceed button - solid light-green pill (PrimaryButton),
                  // matching "splash 2" exactly. Was a custom green-gold-
                  // green gradient button; Figma's Proceed button is flat,
                  // not gradient.
                  PrimaryButton(
                    label: "Proceed",
                    height: 55,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Onboarding1(),
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
    ),
    );
  }
}
