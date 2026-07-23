import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/k54_search_field.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/features/profile/widgets/contact_us_flow.dart';

/// Matches the K54 Figma file's Help Center screen (exported via
/// Figma-to-Code, 2026-07-14 - no node id captured since the API was
/// rate-limited at the time, but colors/typography confirmed against the
/// same shared palette as every other screen). This screen doesn't
/// exist anywhere in the live site or the app's prior BuddyBoss-based
/// feature set, so it's entirely static/local content - no FAQ or
/// ticketing backend exists to wire up. Email/phone contact and Live
/// Chat routing are intentionally "coming soon" (confirmed 2026-07-14:
/// no support account or published contact details exist yet) rather
/// than guessed at.
class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  static const _categories = [
    "Account Issues",
    "App Features",
    "Technical Support",
    "Privacy & Security",
    "Billing & Subscriptions",
    "General Inquiries",
  ];

  static const _faqs = [
    (
      "How do I reset my password?",
      "On the Login screen, tap \"Forgot Password?\" and follow the instructions sent to your email.",
    ),
    (
      "How to change my profile picture?",
      "Go to your Profile, tap Edit, then \"Change Photo\" to upload a new picture.",
    ),
    (
      "How do I manage my subscription?",
      "K54 doesn't have in-app subscriptions right now - this section will update if that changes.",
    ),
  ];

  static const _troubleshooting = [
    "App crashing? Try clearing cache.",
    "Can't log in? Check your password.",
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature is coming soon")),
    );
  }

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget _socialIcon(IconData icon, String platform) {
    return TapScale(
      onTap: () => _comingSoon(platform),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: Color(0xFFFCF8ED), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: AppColors.jetBlack),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.subHeading),
    );
  }

  Widget _row({required IconData icon, required String label, VoidCallback? onTap}) {
    return TapScale(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.jetBlack),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.lato(fontSize: 16, color: AppColors.jetBlack),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories =
        _categories.where((c) => c.toLowerCase().contains(_query.toLowerCase())).toList();
    final filteredFaqs =
        _faqs.where((f) => f.$1.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    "Help Center",
                    style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: K54SearchField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      hintText: "Search help center",
                      height: 32,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              if (filteredCategories.isNotEmpty) ...[
                _sectionTitle("Help Categories"),
                const SizedBox(height: 20),
                Column(
                  children: [
                    for (final c in filteredCategories) ...[
                      _row(icon: Icons.folder_outlined, label: c, onTap: () => _comingSoon(c)),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
              ],

              if (filteredFaqs.isNotEmpty) ...[
                _sectionTitle("Popular Topics"),
                const SizedBox(height: 20),
                Column(
                  children: [
                    for (final faq in filteredFaqs) ...[
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 12),
                        title: Text(
                          faq.$1,
                          style: GoogleFonts.lato(fontSize: 16, color: AppColors.jetBlack),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              faq.$2,
                              style: GoogleFonts.lato(fontSize: 14, color: AppColors.subHeading2),
                            ),
                          ),
                        ],
                      ),
                    ],
                    TapScale(
                      onTap: () => _comingSoon("More help topics"),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Show More",
                          style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF008000)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
              ],

              _sectionTitle("Contact Us"),
              const SizedBox(height: 20),
              _row(
                icon: Icons.email_outlined,
                label: "Email Support",
                onTap: () => _comingSoon("Email support"),
              ),
              const SizedBox(height: 20),
              _row(
                icon: Icons.chat_bubble_outline,
                label: "Live Chat",
                onTap: () => _comingSoon("Live chat"),
              ),
              const SizedBox(height: 20),
              _row(
                icon: Icons.call_outlined,
                label: "Call Us",
                onTap: () => _comingSoon("Phone support"),
              ),
              const SizedBox(height: 26),

              _sectionTitle("Troubleshooting Tips"),
              const SizedBox(height: 20),
              Column(
                children: [
                  for (final tip in _troubleshooting) ...[
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 22, color: AppColors.jetBlack),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(tip, style: GoogleFonts.lato(fontSize: 16, color: AppColors.jetBlack)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
              const SizedBox(height: 6),

              _sectionTitle("Follow Us"),
              const SizedBox(height: 16),
              // No confirmed K54 social accounts exist yet (same "no
              // published contact details" reasoning as Email/Call
              // above), so these are honest coming-soon taps rather than
              // invented profile URLs that would send users to the wrong
              // (or no) account.
              Row(
                children: [
                  _socialIcon(Icons.facebook, "Facebook"),
                  const SizedBox(width: 16),
                  _socialIcon(Icons.camera_alt_outlined, "Instagram"),
                  const SizedBox(width: 16),
                  _socialIcon(Icons.alternate_email, "Twitter"),
                ],
              ),
              const SizedBox(height: 26),

              _row(
                icon: Icons.description_outlined,
                label: "Terms of Service",
                onTap: () => _openUrl("https://k54global.com/terms-of-service/"),
              ),
              const SizedBox(height: 20),
              _row(
                icon: Icons.privacy_tip_outlined,
                label: "Privacy Policy",
                onTap: () => _openUrl("https://k54global.com/privacy-policy/"),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 22, color: AppColors.jetBlack),
                  SizedBox(width: 15),
                  Text(
                    "App Version: 1.0.0",
                    style: TextStyle(fontSize: 16, color: AppColors.jetBlack),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              PrimaryButton(label: "Contact US", height: 48, onPressed: () => showContactUsFlow(context)),
              const SizedBox(height: 12),
              PrimaryButton(
                label: "Cancel",
                height: 48,
                outline: true,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
