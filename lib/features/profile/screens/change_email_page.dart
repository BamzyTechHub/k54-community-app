import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/features/profile/screens/email_verification_pending_page.dart';

/// Wired to the confirmed WordPress core REST endpoint
/// (POST /wp/v2/users/me, field "email" - see AuthService.updateEmail's
/// doc comment). WordPress core itself sends the confirmation link to
/// the old address before the change takes effect - this app doesn't
/// need (or have) a separate "send verification" step, unlike the
/// previous fake "Verify Email" button that showed a snackbar and did
/// nothing.
class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final currentEmailController = TextEditingController();
  final newEmailController = TextEditingController();
  final confirmEmailController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
  }

  Future<void> _loadCurrentEmail() async {
    try {
      final response = await AuthService().getCurrentUser();
      currentEmailController.text = response.data["user_email"] ?? "";
    } catch (_) {
      // Non-fatal - field just stays blank.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    currentEmailController.dispose();
    newEmailController.dispose();
    confirmEmailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (newEmailController.text.trim().isEmpty || confirmEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }
    if (newEmailController.text.trim() != confirmEmailController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Emails do not match")),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final email = newEmailController.text.trim();
      await AuthService().updateEmail(email);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => EmailVerificationPendingPage(email: email)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't update email: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field({required String label, required TextEditingController controller, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF5EFD9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: SafeArea(child: Center(child: CircularProgressIndicator())));
    }

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
                  Text("Change Email", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 25),
              _field(label: "Current Email", controller: currentEmailController, enabled: false),
              _field(label: "New Email", controller: newEmailController),
              _field(label: "Confirm Email", controller: confirmEmailController),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EFD9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.green),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "A verification link will be sent to your current email address before this change takes effect.",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              PrimaryButton(
                label: "Update Email",
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
