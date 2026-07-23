import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/features/auth/screens/login.dart';

/// Matches the K54 Figma file's Logout confirmation + success screens
/// exactly (nodes 437:911 and 437:1061, rendered 2026-07-08). One widget
/// with two local states rather than two routes, since the only thing
/// that changes between them is the icon/copy/button - logout itself
/// (AuthService().logout()) was already real and working, this screen
/// just adds the confirmation step Figma calls for.
class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  bool _loggedOut = false;

  Future<void> _confirmLogout() async {
    await AuthService().logout();
    if (mounted) setState(() => _loggedOut = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Text("Logout", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 60),
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                  child: Icon(
                    _loggedOut ? Icons.check : Icons.close,
                    color: AppColors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Center(
                child: _loggedOut
                    ? Column(
                        children: [
                          Text(
                            "You have been Logged out from this account.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(fontSize: 15, color: AppColors.jetBlack),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Thank you for using k54global!\nWe hope to see you again soon.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(fontSize: 15, color: AppColors.jetBlack),
                          ),
                        ],
                      )
                    : Text(
                        "Are you sure you want to Log out?",
                        style: GoogleFonts.lato(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.green),
                      ),
              ),
              const SizedBox(height: 30),
              if (_loggedOut)
                PrimaryButton(
                  label: "Login",
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const Login()),
                    (route) => false,
                  ),
                )
              else ...[
                PrimaryButton(
                  label: "Logout",
                  onPressed: _confirmLogout,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: "Cancel",
                  outline: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
