import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/features/profile/screens/about_app_page.dart';
import 'package:k54_mobile/features/profile/screens/change_email_page.dart';
import 'package:k54_mobile/features/profile/screens/change_password_page.dart';
import 'package:k54_mobile/features/profile/screens/deactivate_account_page.dart';
import 'package:k54_mobile/features/profile/screens/app_language_page.dart';
import 'package:k54_mobile/features/profile/screens/app_permissions_page.dart';
import 'package:k54_mobile/features/profile/screens/help_center_page.dart';
import 'package:k54_mobile/features/profile/screens/login_activity_page.dart';
import 'package:k54_mobile/features/profile/screens/logout_page.dart';
import 'package:k54_mobile/features/profile/screens/notifications_settings_page.dart';
import 'package:k54_mobile/features/profile/screens/privacy_settings_page.dart';
import 'package:k54_mobile/features/profile/screens/two_factor_auth_page.dart';
import 'package:k54_mobile/features/profile/widgets/profile_actions.dart';
import 'package:k54_mobile/features/profile/widgets/profile_header.dart';
import 'package:k54_mobile/core/widgets/k54_search_field.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';

typedef _SettingsTile = ({IconData icon, String label, VoidCallback onTap});

/// Matches the K54 Figma file's Account Settings screen (node 428:323):
/// the same profile header/action row as Timeline, then three grouped
/// lists, plus a real search-icon-in-header that filters the tiles below
/// (confirmed against a fresh screenshot 2026-07-18 - the header does
/// have a search icon, previously missing entirely here). Only Change
/// Email, Change Password, and Log Out are wired to real, already-
/// confirmed behavior; everything else here has no confirmed backend
/// endpoint (some, like Deactivate Account, are high-risk destructive
/// actions that shouldn't be guessed at regardless) so they show "coming
/// soon" rather than a fake success.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String userName = "";
  String userTitle = "";
  String userImage = "";
  bool _loading = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _searchExpanded = false;
  String _query = "";

  @override
  void initState() {
    super.initState();
    _loadUser();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
        setState(() => _searchExpanded = false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocusNode.requestFocus());
  }

  Future<void> _loadUser() async {
    try {
      final response = await AuthService().getCurrentUser();
      final user = response.data;
      userName = user["name"] ?? "";
      userImage = user["avatar_urls"]?["full"] ?? user["avatar_urls"]?["thumb"] ?? "";
      userTitle = user["xprofile"]?["groups"]?["1"]?["fields"]?["31"]?["value"]?["raw"] ??
          "K54 Community Member";
    } catch (_) {
      // Non-fatal - header just shows placeholders.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _logout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LogoutPage()),
    );
  }

  List<(String title, List<_SettingsTile> tiles)> _sections() {
    return [
      (
        "Account Management / Settings",
        [
          (
            icon: Icons.email_outlined,
            label: "Change Email",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeEmailPage())),
          ),
          (
            icon: Icons.vpn_key_outlined,
            label: "Change Password",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage())),
          ),
          (
            icon: Icons.person_off_outlined,
            label: "Deactivate Account",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeactivateAccountPage())),
          ),
        ],
      ),
      (
        "Security",
        [
          (
            icon: Icons.shield_outlined,
            label: "Two-Factor Authentication",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TwoFactorAuthPage())),
          ),
          (
            icon: Icons.history,
            label: "Login Activity",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginActivityPage())),
          ),
          (
            icon: Icons.admin_panel_settings_outlined,
            label: "App Permissions",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppPermissionsPage())),
          ),
        ],
      ),
      (
        "Settings",
        [
          (
            icon: Icons.notifications_none,
            label: "Notification Settings",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsSettingsPage())),
          ),
          (
            icon: Icons.lock_outline,
            label: "Privacy Settings",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsPage())),
          ),
          (
            icon: Icons.public,
            label: "Language",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppLanguagePage())),
          ),
          (
            icon: Icons.help_outline,
            label: "Help & Support",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterPage())),
          ),
          // Replaces the earlier "Login Information" tile - not in the
          // real Figma header at all (confirmed against a fresh
          // screenshot 2026-07-18), which shows "About the App" here
          // instead.
          (
            icon: Icons.info_outline,
            label: "About the App",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppPage())),
          ),
          (icon: Icons.logout, label: "Log Out", onTap: _logout),
        ],
      ),
    ];
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 20),
      child: Text(
        title,
        style: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.green,
        ),
      ),
    );
  }

  Widget _tileGroup(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        // #FCF8ED - same systemic fix as K54SearchField/AI Assistant's
        // search pill: this was still the stale tan/gold
        // groupCardBackground.
        color: const Color(0xFFFCF8ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: tiles),
    );
  }

  Widget _tile(_SettingsTile tile) {
    return InkWell(
      onTap: tile.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(tile.icon, size: 20, color: AppColors.jetBlack),
            const SizedBox(width: 14),
            Expanded(
              child: Text(tile.label, style: GoogleFonts.lato(fontSize: 15, color: AppColors.jetBlack)),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.jetBlack),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSections = _sections()
        .map((s) => (s.$1, s.$2.where((t) => t.label.toLowerCase().contains(_query)).toList()))
        .where((s) => s.$2.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.green))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Account Settings",
                          style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        TapScale(
                          onTap: _openSearch,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.search, size: 20, color: AppColors.jetBlack),
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _searchExpanded
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: K54SearchField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                hintText: "Search settings...",
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    const SizedBox(height: 12),
                    ProfileHeader(userName: userName, userTitle: userTitle, userImage: userImage),
                    const ProfileActions(isCurrentUser: true),
                    if (filteredSections.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text("No settings match \"${_searchController.text}\"", style: GoogleFonts.lato(color: Colors.grey.shade600)),
                        ),
                      )
                    else
                      for (final section in filteredSections) ...[
                        _sectionTitle(section.$1),
                        _tileGroup(section.$2.map(_tile).toList()),
                      ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
