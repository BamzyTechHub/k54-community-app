import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';

/// Matches the App Language Figma frame exactly (node 497:600, pulled via
/// the REST API 2026-07-16) - the full 26-language list with radio
/// selection. Selecting a language is real, interactive local state, but
/// the app has no localization (l10n) set up at all - only English
/// strings exist anywhere in the codebase - so Save Changes says the
/// change can't actually be applied yet instead of silently doing
/// nothing while claiming success.
class AppLanguagePage extends StatefulWidget {
  const AppLanguagePage({super.key});

  @override
  State<AppLanguagePage> createState() => _AppLanguagePageState();
}

class _AppLanguagePageState extends State<AppLanguagePage> {
  String _selected = "English";

  static const _languages = [
    "English",
    "Spanish (Español)",
    "French (Français)",
    "German (Deutsch)",
    "Italian (Italiano)",
    "Portuguese (Português)",
    "Chinese (中文)",
    "Japanese (日本語)",
    "Korean (한국어)",
    "Hindi (हिन्दी)",
    "Arabic (العربية)",
    "Russian (Русский)",
    "Turkish (Türkçe)",
    "Bengali (বাংলা)",
    "Vietnamese (Tiếng Việt)",
    "Swahili (Kiswahili)",
    "Hebrew (עברית)",
    "Tamil (தமிழ்)",
    "Thai (ไทย)",
    "Greek (Ελληνικά)",
    "Ukrainian (Українська)",
    "Polish (Polski)",
    "Dutch (Nederlands)",
    "Swedish (Svenska)",
    "Serbian (Српски)",
    "Zulu (IsiZulu)",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "App Language",
                    style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  final selected = lang == _selected;
                  return InkWell(
                    onTap: () => setState(() => _selected = lang),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: selected ? AppColors.green : AppColors.jetBlack,
                          ),
                          const SizedBox(width: 10),
                          Text(lang, style: GoogleFonts.lato(fontSize: 16, color: AppColors.jetBlack)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  PrimaryButton(
                    label: "Save Changes",
                    height: 48,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("The app isn't translated yet - only English is available right now."),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: "Cancel",
                    height: 48,
                    outline: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
