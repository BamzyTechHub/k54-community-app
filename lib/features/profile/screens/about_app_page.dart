import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/features/profile/widgets/contact_us_flow.dart';

/// Matches the real K54 Figma "About the App" screen content exactly (the
/// user's own screenshot, 2026-07-21) - the previous version of this
/// screen was invented placeholder copy written before that content was
/// available, not the real design text. Version string still mirrors
/// pubspec.yaml's actual `version: 1.0.0+1` rather than the Figma
/// mockup's placeholder "1.2.3" - showing the real build version here is
/// correct, copying the design's fake one would be dishonest versioning.
class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
    );
  }

  Widget _bullet(String label, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.lato(fontSize: 14, color: AppColors.jetBlack, height: 1.4),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: detail),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                  const SizedBox(width: 10),
                  Text("About The App", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 25),

              _sectionTitle("App Description"),
              const SizedBox(height: 10),
              Text(
                "K54global is a networking and collaborative app designed to help "
                "entrepreneurs manage your personal, business, and professional life "
                "in one place. Whether you need to chat with friends, create posts, "
                "or manage your business contacts, this app provides you with all "
                "the tools you need.",
                style: GoogleFonts.lato(fontSize: 14, color: AppColors.jetBlack, height: 1.5),
              ),
              const SizedBox(height: 22),

              _sectionTitle("Key Features"),
              const SizedBox(height: 10),
              _bullet("Personal", "Instant messaging, group chats, media sharing"),
              _bullet("Business", "Team collaboration, Organized and structured space, file sharing"),
              _bullet("Professional", "Networking, professional communication, event planning"),
              const SizedBox(height: 14),

              _sectionTitle("Version Information"),
              const SizedBox(height: 10),
              Text("App Version: 1.0.0", style: GoogleFonts.lato(fontSize: 14, color: AppColors.jetBlack)),
              const SizedBox(height: 22),

              _sectionTitle("Team Information or Developer Info"),
              const SizedBox(height: 10),
              Text(
                "Developed by K54global, a passionate team dedicated to improving "
                "structured collaboration and communication for users worldwide",
                style: GoogleFonts.lato(fontSize: 14, color: AppColors.jetBlack, height: 1.5),
              ),
              const SizedBox(height: 8),
              TapScale(
                onTap: () => _openUrl("https://k54global.com"),
                child: Text(
                  "Visit our website: www.k54global.com",
                  style: GoogleFonts.lato(fontSize: 14, color: AppColors.green, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 22),

              _sectionTitle("Privacy & Legal Information"),
              const SizedBox(height: 10),
              Text(
                "We take your privacy seriously. Review our Privacy Policy and Terms "
                "of Service for more information.",
                style: GoogleFonts.lato(fontSize: 14, color: AppColors.jetBlack, height: 1.5),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  TapScale(
                    onTap: () => _openUrl("https://k54global.com/privacy-policy/"),
                    child: Text(
                      "Privacy Policy",
                      style: GoogleFonts.lato(fontSize: 14, color: AppColors.green, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 20),
                  TapScale(
                    onTap: () => _openUrl("https://k54global.com/terms-of-service/"),
                    child: Text(
                      "Terms of Service",
                      style: GoogleFonts.lato(fontSize: 14, color: AppColors.green, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              _sectionTitle("Contact Information"),
              const SizedBox(height: 10),
              Text(
                "For any inquiries, please visit our Contact Us page or email us at "
                "support@123.com",
                style: GoogleFonts.lato(fontSize: 14, color: AppColors.jetBlack, height: 1.5),
              ),
              const SizedBox(height: 28),

              PrimaryButton(label: "Contact Us", height: 48, onPressed: () => showContactUsFlow(context)),
              const SizedBox(height: 12),
              PrimaryButton(
                label: "Cancel",
                height: 48,
                outline: true,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
