import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';

/// Matches the Two-Factor Authentication Figma frame exactly (node
/// 469:290, pulled via the REST API 2026-07-16) - it's an OTP-entry
/// screen (6-digit code), not a settings toggle page. Built full UI +
/// real navigation + interactive OTP boxes per the 2026-07-16 directive:
/// "build the screen exactly as designed... only disable or stop at the
/// final action that requires a real backend."
///
/// There is no confirmed 2FA/OTP REST endpoint anywhere in this WordPress
/// setup (no plugin evidence, no route in AuthService) - so both Verify
/// and Resend stop short of a real network call and say so plainly,
/// rather than faking success.
class TwoFactorAuthPage extends StatefulWidget {
  const TwoFactorAuthPage({super.key});

  @override
  State<TwoFactorAuthPage> createState() => _TwoFactorAuthPageState();
}

class _TwoFactorAuthPageState extends State<TwoFactorAuthPage> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool _showError = false;

  bool get _codeComplete => _controllers.every((c) => c.text.trim().isNotEmpty);

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_showError) _showError = false;
    setState(() {});
  }

  // No confirmed 2FA/OTP backend exists (see class doc comment) - any
  // code entered can only ever be wrong, so the real, honest outcome of
  // tapping Verify is always this Figma "Error Alert" card, never the
  // "Identity Verified" success card (which would require an actual
  // backend to legitimately show).
  void _handleVerify() {
    setState(() => _showError = true);
  }

  void _retry() {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() => _showError = false);
    _focusNodes.first.requestFocus();
  }

  void _notAvailable(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$action isn't available yet - no 2FA backend is configured.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
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
                    "Two-Factor Authentication",
                    style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.shield_outlined, color: AppColors.white, size: 60),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "We've sent a 6-digit code to your email/phone number. Enter the code below to verify your identity.",
                style: GoogleFonts.lato(fontSize: 16, color: AppColors.jetBlack),
              ),
              const SizedBox(height: 20),
              if (_showError) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCF8ED),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        "The code you entered is incorrect. Please try again.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.jetBlack),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(label: "Retry", height: 42, onPressed: _retry),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _otpBox(index)),
              ),
              const SizedBox(height: 17),
              PrimaryButton(
                label: "Verify",
                height: 48,
                onPressed: _codeComplete ? _handleVerify : null,
              ),
              const SizedBox(height: 20),
              Center(
                child: _ResendTimer(onExpiredTap: () => _notAvailable("Resending a code")),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 43,
      height: 40,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
        decoration: InputDecoration(
          counterText: "",
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: AppColors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.green),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.green),
          ),
        ),
        onChanged: (value) => _onDigitChanged(index, value),
      ),
    );
  }
}

/// Local, honest countdown - it never claims a code was actually resent
/// since there's no backend to resend one. Once expired, tapping surfaces
/// the same "not available" message as Verify rather than restarting the
/// timer as if something happened.
class _ResendTimer extends StatefulWidget {
  final VoidCallback onExpiredTap;

  const _ResendTimer({required this.onExpiredTap});

  @override
  State<_ResendTimer> createState() => _ResendTimerState();
}

class _ResendTimerState extends State<_ResendTimer> {
  int _seconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expired = _seconds == 0;
    return GestureDetector(
      onTap: expired ? widget.onExpiredTap : null,
      child: Text(
        expired ? "Resend Code" : "Resend Code in ${_seconds}s",
        style: GoogleFonts.lato(
          fontSize: 16,
          color: expired ? AppColors.green : AppColors.jetBlack,
          fontWeight: expired ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}
