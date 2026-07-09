import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';

/// No confirmed backend endpoint exists for account deactivation - it's
/// also a high-risk destructive action, so this deliberately stops at a
/// full UI shell rather than guessing at (and possibly firing) a wrong
/// request. Matches the Change Password screen's layout for consistency.
class DeactivateAccountPage extends StatefulWidget {
  const DeactivateAccountPage({super.key});

  @override
  State<DeactivateAccountPage> createState() => _DeactivateAccountPageState();
}

class _DeactivateAccountPageState extends State<DeactivateAccountPage> {
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _confirmChecked = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account deactivation isn't available yet")),
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
                  Text("Deactivate Account", style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Deactivating your account will hide your profile, posts, and activity from other members. You can reactivate by logging back in.",
                style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _passwordController,
                obscureText: _hidePassword,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  filled: true,
                  fillColor: const Color(0xFFF5EFD9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  suffixIcon: IconButton(
                    icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() => _confirmChecked = !_confirmChecked),
                child: Row(
                  children: [
                    Checkbox(
                      value: _confirmChecked,
                      activeColor: AppColors.green,
                      onChanged: (v) => setState(() => _confirmChecked = v ?? false),
                    ),
                    Expanded(
                      child: Text("I understand this will deactivate my account", style: GoogleFonts.lato(fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (_confirmChecked && _passwordController.text.isNotEmpty) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Deactivate Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
