import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';

/// Matches the App Permissions Figma frame exactly (node 480:639, pulled
/// via the REST API 2026-07-16). The 4 toggles are real, interactive
/// local UI state (they don't require any WordPress/BuddyBoss backend -
/// these are OS-level permissions), but aren't wired to the actual
/// Android permission system yet (no permission_handler dependency in
/// this project - adding a new native-capability package right before a
/// delivery deadline is exactly the kind of change worth flagging rather
/// than doing silently). Save Changes says so explicitly rather than
/// pretending the toggle state was persisted anywhere.
class AppPermissionsPage extends StatefulWidget {
  const AppPermissionsPage({super.key});

  @override
  State<AppPermissionsPage> createState() => _AppPermissionsPageState();
}

class _AppPermissionsPageState extends State<AppPermissionsPage> {
  bool _location = false;
  bool _camera = false;
  bool _microphone = false;
  bool _notifications = false;

  void _notAvailable(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$action isn't available yet - not wired to the OS permission system.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    "App Permissions",
                    style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Review and manage the permissions you've granted.",
                style: GoogleFonts.lato(fontSize: 16, color: AppColors.jetBlack),
              ),
              const SizedBox(height: 25),
              _permissionRow(
                title: "Location Access",
                icon: Icons.location_on_outlined,
                label: "Allow app to access your location",
                value: _location,
                onChanged: (v) => setState(() => _location = v),
              ),
              _permissionRow(
                title: "Camera Access",
                icon: Icons.photo_camera_outlined,
                label: "Allow app to use your camera for calls",
                value: _camera,
                onChanged: (v) => setState(() => _camera = v),
              ),
              _permissionRow(
                title: "Microphone Access",
                icon: Icons.mic_none_outlined,
                label: "Allow app to use your microphone",
                value: _microphone,
                onChanged: (v) => setState(() => _microphone = v),
              ),
              _permissionRow(
                title: "Notifications",
                icon: Icons.notifications_none_outlined,
                label: "Allow app to send notifications",
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
              ),
              const SizedBox(height: 15),
              // All three are plain green text links, matching the Figma
              // screenshot exactly - Save Changes/Contact Support were
              // previously styled as buttons (a filled PrimaryButton and
              // an outline one), which doesn't match Reset All
              // Permissions' plain-link treatment right above them.
              _textLink(
                "Reset All Permissions",
                () => setState(() {
                  _location = false;
                  _camera = false;
                  _microphone = false;
                  _notifications = false;
                }),
              ),
              _textLink("Save Changes", () => _notAvailable("Saving permission changes")),
              _textLink("Contact Support", () => _notAvailable("Contact Support")),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: GoogleFonts.lato(fontSize: 16, color: AppColors.green, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _permissionRow({
    required String title,
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.jetBlack),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 22, color: AppColors.jetBlack),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.lato(fontSize: 16, color: AppColors.jetBlack),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
