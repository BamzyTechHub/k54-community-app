import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';

/// Static app info - no backend involved, nothing to fake. Version
/// string mirrors pubspec.yaml's current `version: 1.0.0+1` directly
/// rather than adding a new dependency (package_info_plus) just to read
/// it dynamically for one line of text on one screen.
class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                  const SizedBox(width: 10),
                  Text("About the App", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    Image.asset("assets/images/k54_logo.png", width: 90, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                    const SizedBox(height: 16),
                    Text("K54 Global", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text("Version 1.0.0", style: GoogleFonts.lato(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "K54 Global connects a community of learners, professionals, and organizations - courses, groups, messaging, and a shared social feed, all in one place.",
                style: GoogleFonts.lato(fontSize: 14, color: AppColors.jetBlack, height: 1.5),
              ),
              const SizedBox(height: 20),
              Text(
                "© ${DateTime.now().year} K54 Global",
                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
