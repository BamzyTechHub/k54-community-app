import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';

/// Inline error/success feedback card - matches the Figma "Error
/// Handling message" / "Success Update" designs used on Change Email,
/// Change Password, and similar forms. Replaces plain SnackBars, which
/// don't match those designs and disappear before the user necessarily
/// reads them.
class InlineErrorCard extends StatelessWidget {
  final String message;

  const InlineErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF8ED),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        message,
        style: GoogleFonts.lato(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class InlineSuccessCard extends StatelessWidget {
  final String message;

  const InlineSuccessCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF8ED),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.jetBlack),
          ),
        ],
      ),
    );
  }
}
