import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/features/profile/screens/change_email_page.dart';
import 'package:k54_mobile/features/profile/screens/change_password_page.dart';
import 'package:k54_mobile/features/profile/screens/deactivate_account_page.dart';
import 'package:k54_mobile/features/profile/screens/logout_page.dart';
import 'package:k54_mobile/features/profile/widgets/profile_actions.dart';
import 'package:k54_mobile/features/profile/widgets/profile_header.dart';

/// Matches the K54 Figma file's Account Settings screen exactly (node
/// 428:323, rendered 2026-07-08): the same profile header/action row as
/// Timeline, then three grouped lists. Only Change Email, Change
/// Password, and Log Out are wired to real, already-confirmed behavior;
/// everything else here has no confirmed backend endpoint (some, like
/// Deactivate Account, are high-risk destructive actions that shouldn't
/// be guessed at regardless) so they show "coming soon" rather than a
/// fake success.
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

  @override
  void initState() {
    super.initState();
    _loadUser();
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

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature is coming soon")),
    );
  }

  void _logout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LogoutPage()),
    );
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
        color: AppColors.groupCardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: tiles),
    );
  }

  Widget _tile({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.jetBlack),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: GoogleFonts.lato(fontSize: 15, color: AppColors.jetBlack)),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.jetBlack),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    ProfileHeader(userName: userName, userTitle: userTitle, userImage: userImage),
                    const ProfileActions(isCurrentUser: true),
                    _sectionTitle("Account Management / Settings"),
                    _tileGroup([
                      _tile(
                        icon: Icons.email_outlined,
                        title: "Change Email",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangeEmailPage()),
                        ),
                      ),
                      _tile(
                        icon: Icons.vpn_key_outlined,
                        title: "Change Password",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                        ),
                      ),
                      _tile(
                        icon: Icons.person_off_outlined,
                        title: "Deactivate Account",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DeactivateAccountPage()),
                        ),
                      ),
                    ]),
                    _sectionTitle("Security"),
                    _tileGroup([
                      _tile(
                        icon: Icons.shield_outlined,
                        title: "Two-Factor Authentication",
                        onTap: () => _comingSoon("Two-factor authentication"),
                      ),
                      _tile(
                        icon: Icons.history,
                        title: "Login Activity",
                        onTap: () => _comingSoon("Login activity"),
                      ),
                      _tile(
                        icon: Icons.admin_panel_settings_outlined,
                        title: "App Permissions",
                        onTap: () => _comingSoon("App permissions"),
                      ),
                    ]),
                    _sectionTitle("Settings"),
                    _tileGroup([
                      _tile(
                        icon: Icons.person_outline,
                        title: "Login Information",
                        onTap: () => _comingSoon("Login information"),
                      ),
                      _tile(
                        icon: Icons.notifications_none,
                        title: "Notification Settings",
                        onTap: () => _comingSoon("Notification settings"),
                      ),
                      _tile(
                        icon: Icons.lock_outline,
                        title: "Privacy Settings",
                        onTap: () => _comingSoon("Privacy settings"),
                      ),
                      _tile(
                        icon: Icons.public,
                        title: "Language",
                        onTap: () => _comingSoon("Language selection"),
                      ),
                      _tile(
                        icon: Icons.help_outline,
                        title: "Help & Support",
                        onTap: () => _comingSoon("Help & support"),
                      ),
                      _tile(
                        icon: Icons.logout,
                        title: "Log Out",
                        onTap: _logout,
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
