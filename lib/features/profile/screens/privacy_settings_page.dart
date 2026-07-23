import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/features/profile/screens/privacy_visibility_pages.dart';
import 'package:k54_mobile/features/profile/screens/profile_field_visibility_page.dart';

/// Matches the Privacy Settings Figma frame (node 491:290).
///
/// "Profile Visibility" is now real - confirmed live 2026-07-20, BuddyBoss
/// genuinely has a per-xprofile-field visibility setting (Public/All
/// Members/My Connections/Only Me per field), just not shaped like this
/// row's old fake 3-option picker; it now opens
/// [ProfileFieldVisibilityPage], the real thing. Every other row here
/// (Last Seen, Profile Picture Visibility, Who Can Message Me, Who Can
/// Add Me to Groups, Location Sharing, Data Collection, Third-Party
/// Access, Notify on Screenshot) has no equivalent anywhere in the site's
/// confirmed REST surface (checked the full 842-route index) - these stay
/// real, interactive local UI state with an honest "not available"
/// disclosure on Save, same as before.
///
/// Corrected 2026-07-18 against fresh Figma screenshots: Profile
/// Visibility / Last Seen / Profile Picture Visibility / Who Can Message
/// Me / Who Can Add Me to Groups each push their own dedicated
/// single-choice screen (see privacy_visibility_pages.dart) rather than
/// an inline dropdown - Location Sharing is the one row that stays an
/// inline dropdown, since no dedicated sub-page exists for it in the
/// reference. "Last Seen" itself was missing entirely before this pass.
class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  String _lastSeen = "Everyone";
  String _onlineVisibility = "Same as last seen";
  String _profilePictureVisibility = "Everyone";
  String _whoCanMessage = "Everyone";
  String _whoCanAddToGroups = "My Contacts";
  String _locationSharing = "While Using App";
  bool _dataCollection = true;
  bool _thirdPartyAccess = false;
  bool _notifyOnScreenshot = true;

  // "Only Me" for the two visibility screens, "Nobody" for the two
  // permission screens - confirmed as genuinely different third options
  // across the Figma sub-page screenshots, not a naming slip.
  static const _visibilityOptions = ["Everyone", "My Contacts", "Only Me"];
  static const _permissionOptions = ["Everyone", "My Contacts", "Nobody"];
  static const _locationOptions = ["While Using App", "Always", "Never"];

  void _notAvailable(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$action isn't available yet - no privacy-settings backend is configured.")),
    );
  }

  Future<void> _pushRadioSelect({
    required String title,
    required String subtitle,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => RadioSelectPage(title: title, subtitle: subtitle, options: options, selectedValue: current),
      ),
    );
    if (result != null) onSelected(result);
  }

  Future<void> _pushLastSeen() async {
    final result = await Navigator.push<({String lastSeen, String online})>(
      context,
      MaterialPageRoute(
        builder: (_) => LastSeenPage(initialLastSeen: _lastSeen, initialOnlineVisibility: _onlineVisibility),
      ),
    );
    if (result != null) {
      setState(() {
        _lastSeen = result.lastSeen;
        _onlineVisibility = result.online;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                    "Privacy Settings",
                    style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Who can see my profile and activities",
                style: GoogleFonts.lato(fontSize: 16, color: AppColors.jetBlack),
              ),
              const SizedBox(height: 25),
              _navRow(
                "Profile Visibility",
                "Manage",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileFieldVisibilityPage()),
                ),
              ),
              _navRow("Last Seen", _lastSeen, _pushLastSeen),
              _navRow(
                "Profile Picture Visibility",
                _profilePictureVisibility,
                () => _pushRadioSelect(
                  title: "Profile Picture Visibility",
                  subtitle: "Who can view my profile picture",
                  options: _visibilityOptions,
                  current: _profilePictureVisibility,
                  onSelected: (v) => setState(() => _profilePictureVisibility = v),
                ),
              ),
              _navRow(
                "Who Can Message Me",
                _whoCanMessage,
                () => _pushRadioSelect(
                  title: "Who Can Message Me",
                  subtitle: "Who can send me direct messages",
                  options: _permissionOptions,
                  current: _whoCanMessage,
                  onSelected: (v) => setState(() => _whoCanMessage = v),
                ),
              ),
              _navRow(
                "Who Can Add Me to Groups",
                _whoCanAddToGroups,
                () => _pushRadioSelect(
                  title: "Who Can Add Me To Groups",
                  subtitle: "Who can add me to group chats",
                  options: _permissionOptions,
                  current: _whoCanAddToGroups,
                  onSelected: (v) => setState(() => _whoCanAddToGroups = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Blocked Contacts",
                        style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.jetBlack)),
                    const SizedBox(height: 4),
                    Text("You have no blocked contacts",
                        style: GoogleFonts.lato(fontSize: 16, color: AppColors.jetBlack)),
                  ],
                ),
              ),
              _dropdownRow("Location Sharing", _locationSharing, _locationOptions,
                  (v) => setState(() => _locationSharing = v)),
              _toggleRow(
                title: "Data Collection",
                label: "Allow Data Collection",
                value: _dataCollection,
                onChanged: (v) => setState(() => _dataCollection = v),
              ),
              _toggleRow(
                title: "Third-Party Access",
                label: "Allow Third-Party Access",
                value: _thirdPartyAccess,
                onChanged: (v) => setState(() => _thirdPartyAccess = v),
              ),
              _toggleRow(
                // Fixed typo ("Screenshoted" -> "Screenshotted") while
                // matching this row against Figma.
                title: "Notify When Screenshotted",
                label:
                    "Users can opt to receive a notification when someone screenshots their message or media.",
                value: _notifyOnScreenshot,
                onChanged: (v) => setState(() => _notifyOnScreenshot = v),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: "Save Changes",
                height: 48,
                onPressed: () => _notAvailable("Saving privacy settings"),
              ),
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

  Widget _navRow(String title, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.jetBlack)),
            ),
            Text(value, style: GoogleFonts.lato(fontSize: 14, color: AppColors.greyShade600)),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.jetBlack),
          ],
        ),
      ),
    );
  }

  Widget _dropdownRow(String title, String value, List<String> options, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.jetBlack)),
          const SizedBox(height: 4),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            style: GoogleFonts.lato(fontSize: 16, color: AppColors.jetBlack),
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required String title,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.jetBlack)),
                const SizedBox(height: 4),
                Text(label, style: GoogleFonts.lato(fontSize: 16, color: AppColors.jetBlack)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.green,
          ),
        ],
      ),
    );
  }
}
