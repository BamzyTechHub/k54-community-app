import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/state_views.dart';
import 'package:k54_mobile/features/profile/screens/change_password_page.dart';

/// Matches the Login Activity Figma frame's layout exactly (node
/// 477:446, pulled via the REST API 2026-07-16): header, subtitle, a
/// login-history list, then Log out from other devices / Change
/// Password / Contact Support links. The Figma mockup's history entries
/// ("Jan 30, 2025 | 10:45 AM", "Mobile", "New York, USA"...) are
/// placeholder content, not real data - there's no confirmed WordPress/
/// BuddyBoss login-history REST endpoint, so this shows an honest empty
/// state for the list instead of displaying invented login records as if
/// they were real. Change Password links to the real, already-wired
/// page; the other two links stop and say so.
class LoginActivityPage extends StatelessWidget {
  const LoginActivityPage({super.key});

  void _notAvailable(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$action isn't available yet - no login-history backend is configured.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Login Activity",
                    style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Review your recent login history for security purposes",
                style: GoogleFonts.lato(fontSize: 16, color: AppColors.jetBlack),
              ),
              const SizedBox(height: 12),
              Text(
                "Login History",
                style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.jetBlack),
              ),
              const K54EmptyState(
                icon: Icons.history,
                message: "Login history isn't available yet",
              ),
              const SizedBox(height: 8),
              _link(context, "Log out from other devices", () => _notAvailable(context, "Logging out other devices")),
              _link(
                context,
                "Change Password",
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage())),
              ),
              _link(context, "Contact Support", () => _notAvailable(context, "Contact Support")),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _link(BuildContext context, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: GoogleFonts.lato(fontSize: 16, color: AppColors.green, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
