import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';

/// BuddyBoss/WordPress don't expose a REST endpoint for password reset
/// (confirmed via GET /wp-json/ - no bdpwr or lost-password route in the
/// index), so this loads the site's own real "lost password" form instead
/// of simulating the flow - the same account-recovery logic the website
/// itself relies on, not a parallel implementation.
class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() =>
      _ForgotPasswordState();
}

class _ForgotPasswordState
    extends State<ForgotPassword> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(
        Uri.parse("https://k54global.com/wp-login.php?action=lostpassword"),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // No generic Material AppBar - the Forgot Password Figma frame
      // uses the same "logo + big centered heading" header as every
      // other screen in this auth flow (Login/Sign Up/Touch ID/Face ID),
      // not a back-arrow app-bar strip. Only the chrome changes here;
      // the real WebView content below is untouched - there's still no
      // confirmed password-reset REST endpoint to build a native form
      // against, so faking one isn't on the table regardless of header
      // styling.
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.jetBlack),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Image.asset("assets/images/k54_logo.png", width: 100),
                        const SizedBox(height: 12),
                        const Text(
                          "Forgot Password",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.jetBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // balances the back button so the header stays centered
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_loading) const Center(child: CircularProgressIndicator(color: AppColors.green)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
