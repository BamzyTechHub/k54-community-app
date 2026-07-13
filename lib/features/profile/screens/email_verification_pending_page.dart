import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';

/// Shown after Change Email successfully calls the real WP-core endpoint
/// (POST /wp/v2/users/me) - WordPress genuinely emails a confirmation
/// link before the change takes effect, so this screen reflects real,
/// confirmed backend behavior, not a placeholder.
class EmailVerificationPendingPage extends StatelessWidget {
  final String email;

  const EmailVerificationPendingPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                child: const Icon(Icons.mark_email_unread_outlined, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 24),
              Text(
                "Confirm your new email",
                style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "We've sent a confirmation link to $email. Your email won't change until you click it.",
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 30),
              PrimaryButton(
                label: "Done",
                height: 52,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
