import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/widgets/inline_status_card.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';

/// Wired to the confirmed WordPress core REST endpoint
/// (POST /wp/v2/users/me, field "password" - see
/// AuthService.updatePassword's doc comment). That endpoint has no
/// "verify current password" mechanism of its own (the request is
/// already authenticated via the app's JWT, so supplying a new password
/// value simply replaces it) - the "Current Password" field here is a
/// client-side confirmation step only, not something sent to or checked
/// against the API, and is labeled accordingly.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hideCurrentPassword = true;
  bool hideNewPassword = true;
  bool hideConfirmPassword = true;
  bool _saving = false;
  String? _errorMessage;
  bool _succeeded = false;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // A special character is required client-side even though the real
  // WordPress endpoint (POST /wp/v2/users/me) has no password-complexity
  // rule of its own - matches the Figma "General Validation" card, which
  // is a real UX requirement this form should enforce regardless of what
  // the backend would otherwise accept.
  static final _specialCharPattern = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=]');

  Future<void> _save() async {
    setState(() {
      _errorMessage = null;
      _succeeded = false;
    });

    if (currentPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      setState(() => _errorMessage = "Please fill all fields");
      return;
    }
    if (newPasswordController.text != confirmPasswordController.text) {
      // Matches the Figma "Password Error Handling message" card exactly.
      setState(() => _errorMessage = "Passwords do not match");
      return;
    }
    if (newPasswordController.text.length < 8) {
      setState(() => _errorMessage = "Password must be at least 8 characters");
      return;
    }
    if (!_specialCharPattern.hasMatch(newPasswordController.text)) {
      // Matches the Figma "General Validation" card exactly.
      setState(() => _errorMessage = "Password must contain at least one special character");
      return;
    }

    setState(() => _saving = true);
    try {
      await AuthService().updatePassword(newPasswordController.text);
      if (!mounted) return;
      setState(() => _succeeded = true);
      // Lets the inline success card (matching Figma's "Password Success
      // Update" design) actually be seen before returning, instead of an
      // instant pop that only a SnackBar briefly announced.
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = "Couldn't update password: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    // Plain label above the field, not a floating InputDecoration label -
    // matches the Figma screenshot.
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.black87)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: hidden,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5EFD9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              suffixIcon: IconButton(
                icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: onToggle,
              ),
            ),
          ),
        ],
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
                  Text("Change Password", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 25),
              if (_succeeded)
                const InlineSuccessCard(message: "Your password has been successfully updated"),
              if (_errorMessage != null) InlineErrorCard(message: _errorMessage!),
              _passwordField(
                label: "Current Password",
                controller: currentPasswordController,
                hidden: hideCurrentPassword,
                onToggle: () => setState(() => hideCurrentPassword = !hideCurrentPassword),
              ),
              _passwordField(
                label: "New Password",
                controller: newPasswordController,
                hidden: hideNewPassword,
                onToggle: () => setState(() => hideNewPassword = !hideNewPassword),
              ),
              _passwordField(
                label: "Confirm New Password",
                controller: confirmPasswordController,
                hidden: hideConfirmPassword,
                onToggle: () => setState(() => hideConfirmPassword = !hideConfirmPassword),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: "Update Password",
                loading: _saving,
                onPressed: _save,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
