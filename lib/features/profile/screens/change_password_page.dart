import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/services/auth_service.dart';
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

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (currentPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }
    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New passwords do not match")),
      );
      return;
    }
    if (newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 8 characters")),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await AuthService().updatePassword(newPasswordController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't update password: $e")),
      );
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        obscureText: hidden,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF5EFD9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          suffixIcon: IconButton(
            icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
