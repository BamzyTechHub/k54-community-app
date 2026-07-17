import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/features/auth/screens/login.dart';

/// Matches the Figma "Deactivate Account" flow: a deactivate-vs-delete
/// choice, a reason field, a password confirmation, a red irreversible-
/// deletion warning when Delete is selected, and two distinct outcome
/// screens (AccountDeactivatedPage / AccountDeletedPage, both built
/// below and reachable via the "preview" route, see their doc comments).
///
/// No confirmed self-service deactivation/deletion REST endpoint exists
/// for a regular member - `DELETE /wp/v2/users/{id}` requires the
/// delete_users capability regular members don't have, and Better
/// Messages' matching routes (`admin/deleteAccount`,
/// `admin/deleteAccountMessages`, checked live 2026-07-18) are
/// explicitly under its admin namespace, not self-service. This is also
/// a high-risk, irreversible destructive action - both reasons this
/// deliberately stops at a full, real UI rather than guessing at (and
/// possibly firing) a wrong or destructive request. Tapping the final
/// confirm button says so plainly instead of navigating to a fake
/// success screen.
class DeactivateAccountPage extends StatefulWidget {
  const DeactivateAccountPage({super.key});

  @override
  State<DeactivateAccountPage> createState() => _DeactivateAccountPageState();
}

enum _AccountAction { deactivate, delete }

class _DeactivateAccountPageState extends State<DeactivateAccountPage> {
  final _passwordController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _hidePassword = true;
  _AccountAction _action = _AccountAction.deactivate;

  @override
  void initState() {
    super.initState();
    // Drives the confirm button's disabled state live as the user types.
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final isDelete = _action == _AccountAction.delete;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isDelete ? "Can't delete account yet" : "Can't deactivate account yet"),
        content: Text(
          "There's no way to ${isDelete ? 'delete' : 'deactivate'} your own account from the app yet - "
          "this action needs a real backend endpoint that doesn't exist for regular members. "
          "Contact support if you need this done manually.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("OK")),
        ],
      ),
    );
  }

  Widget _optionCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCF8ED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _optionRow(
            label: "Deactivate My Account",
            selected: _action == _AccountAction.deactivate,
            onTap: () => setState(() => _action = _AccountAction.deactivate),
          ),
          const Divider(height: 1),
          _optionRow(
            label: "Delete My Account",
            warning: true,
            selected: _action == _AccountAction.delete,
            onTap: () => setState(() => _action = _AccountAction.delete),
          ),
        ],
      ),
    );
  }

  Widget _optionRow({required String label, required bool selected, required VoidCallback onTap, bool warning = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.lato(fontSize: 15, color: AppColors.jetBlack)),
            if (warning) ...[
              const SizedBox(width: 6),
              const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
              const SizedBox(width: 4),
              Text("irreversible", style: GoogleFonts.lato(fontSize: 12, color: Colors.orange.shade800)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    final isDelete = _action == _AccountAction.delete;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF8ED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: isDelete ? "Deleting your account will:\n" : "Deactivating your account will:\n",
              style: GoogleFonts.lato(fontWeight: FontWeight.w600, color: AppColors.jetBlack),
            ),
            TextSpan(
              text: isDelete
                  ? "- Permanently remove your profile, posts, and messages\n"
                    "- Permanently release your email/username for reuse\n\n"
                    "This can't be undone."
                  : "- Temporarily hide your profile\n"
                    "- Disable your ability to receive messages\n\n"
                    "You can reactivate your account anytime by logging back in.",
              style: GoogleFonts.lato(color: AppColors.jetBlack),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDelete = _action == _AccountAction.delete;

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
                  Text("Deactivate Account", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "We're sorry to see you go! Deactivating your account will temporarily hide your profile and prevent "
                "other users from sending you messages. You can reactivate your account later.",
                style: GoogleFonts.lato(fontSize: 13, color: AppColors.green, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Text("Account Deactivation Options",
                  style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.jetBlack)),
              const SizedBox(height: 10),
              _optionCard(),
              const SizedBox(height: 16),
              _infoCard(),
              const SizedBox(height: 20),
              Text("Why are you ${isDelete ? 'deleting' : 'deactivating'} your account?",
                  style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  hintText: "Share your reason...",
                  filled: true,
                  fillColor: const Color(0xFFF5EFD9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              Text("Please enter your password to confirm:",
                  style: GoogleFonts.lato(fontSize: 14, color: AppColors.jetBlack)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _hidePassword,
                decoration: InputDecoration(
                  hintText: "Enter password",
                  filled: true,
                  fillColor: const Color(0xFFF5EFD9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  suffixIcon: IconButton(
                    icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  ),
                ),
              ),
              if (isDelete) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCF8ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "WARNING: Deleting your account is irreversible.\n",
                          style: GoogleFonts.lato(fontWeight: FontWeight.w700, color: Colors.red.shade700),
                        ),
                        TextSpan(
                          text: "All your data will be lost permanently.\nAre you sure you want to proceed?",
                          style: GoogleFonts.lato(color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: isDelete ? "Yes, Delete My Account" : "Yes, Deactivate My Account",
                onPressed: _passwordController.text.isEmpty ? null : _submit,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: "No, Keep My Account",
                outline: true,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Account Successfully Deactivated!" outcome screen from Figma -
/// built for real (not skipped) so the full designed flow exists, but
/// nothing in this codebase navigates to it, since DeactivateAccountPage
/// never claims that outcome actually happened (no real backend exists
/// to deactivate an account - see its own doc comment). Kept reachable
/// only for direct review against Figma.
class AccountDeactivatedPage extends StatelessWidget {
  const AccountDeactivatedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                Text(
                  "Account Successfully Deactivated!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  "You can reactivate your account at any time by logging back in.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: "Reactivate Account",
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "Your Account Has Been Deleted" outcome screen - same "built but
/// unreachable from a real action" reasoning as AccountDeactivatedPage
/// above.
class AccountDeletedPage extends StatelessWidget {
  const AccountDeletedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                Text(
                  "Your Account Has Been Deleted",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  "All data associated with your account has been permanently removed.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: "Back To Login",
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const Login()),
                    (route) => false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
