import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';

/// The "Contact Us" flow shared by Help Center and About the App - a
/// bottom sheet choosing a support channel (Email/Live Chat/Call/Report a
/// Bug/Visit Help Center), matching the Figma "Contact Us popup Screen"
/// exactly. Only "Live Chat Support" leads anywhere further (the message
/// box, "We would respond to you in the K54 chat") since it's the one
/// channel this app can plausibly route through its own chat later - the
/// others have no confirmed contact address/number to send to, so they're
/// honest coming-soon taps rather than invented ones.
Future<void> showContactUsFlow(BuildContext context) async {
  final option = await showK54BottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined, color: AppColors.jetBlack),
            title: const Text("Email Support"),
            onTap: () => Navigator.pop(sheetContext, "email"),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline, color: AppColors.jetBlack),
            title: const Text("Live Chat Support"),
            onTap: () => Navigator.pop(sheetContext, "chat"),
          ),
          ListTile(
            leading: const Icon(Icons.call_outlined, color: AppColors.jetBlack),
            title: const Text("Call Us"),
            onTap: () => Navigator.pop(sheetContext, "call"),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined, color: AppColors.jetBlack),
            title: const Text("Report a Bug"),
            onTap: () => Navigator.pop(sheetContext, "bug"),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.jetBlack),
            title: const Text("Visit Help Center"),
            onTap: () => Navigator.pop(sheetContext, null),
          ),
        ],
      ),
    ),
  );

  if (!context.mounted || option == null) return;
  switch (option) {
    case "chat":
      await _showMessageDialog(context);
      break;
    case "email":
      _comingSoon(context, "Email support");
      break;
    case "call":
      _comingSoon(context, "Phone support");
      break;
    case "bug":
      _comingSoon(context, "Bug reporting");
      break;
  }
}

void _comingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("$feature is coming soon")),
  );
}

Future<void> _showMessageDialog(BuildContext context) async {
  final messageController = TextEditingController();
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: K54Dialog.shape,
      title: Text(
        "We would respond to you in the K54 chat",
        style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.green),
      ),
      content: TextField(
        controller: messageController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: "Tell us how we can help",
          filled: true,
          fillColor: const Color(0xFFFCF8ED),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        // Single "Send" button - matches the Figma "Contact Us popup
        // Screen" exactly (no separate Cancel button here; dismissing the
        // dialog itself is the cancel action).
        SizedBox(
          width: double.infinity,
          child: TapScale(
            onTap: () {
              Navigator.pop(dialogContext);
              _comingSoon(context, "Sending a support message");
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(16)),
              child: const Center(
                child: Text(
                  "Send",
                  style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
