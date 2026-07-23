import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';

/// Matches the App Permissions Figma frame exactly (node 480:639, pulled
/// via the REST API 2026-07-16). These are genuine OS-level permissions
/// (no WordPress/BuddyBoss backend involved at all) - now wired to the
/// real Android/iOS permission system via `permission_handler` rather
/// than local-only toggles. Each switch reflects the actual current OS
/// grant state on load; turning one ON fires the real system permission
/// prompt; turning one OFF (which apps can't do programmatically once
/// granted) opens the OS app-settings page so the user can revoke it
/// there for real, rather than silently flipping a switch that lies
/// about the actual permission state.
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    final results = await Future.wait([
      Permission.location.status,
      Permission.camera.status,
      Permission.microphone.status,
      Permission.notification.status,
    ]);
    if (!mounted) return;
    setState(() {
      _location = results[0].isGranted;
      _camera = results[1].isGranted;
      _microphone = results[2].isGranted;
      _notifications = results[3].isGranted;
      _loading = false;
    });
  }

  Future<void> _toggle(Permission permission, bool turnOn, ValueChanged<bool> setLocal) async {
    if (!turnOn) {
      // Apps can't programmatically revoke a permission they were
      // granted - the only real path is the OS's own app-settings page.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Opening system settings so you can revoke this permission")),
      );
      await openAppSettings();
      _loadStatuses();
      return;
    }

    final status = await permission.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => setLocal(true));
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission was denied - enable it from system settings instead")),
      );
      await openAppSettings();
      _loadStatuses();
    } else {
      setState(() => setLocal(false));
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
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(color: AppColors.green),
                ),
              _permissionRow(
                title: "Location Access",
                icon: Icons.location_on_outlined,
                label: "Allow app to access your location",
                value: _location,
                onChanged: (v) => _toggle(Permission.location, v, (val) => _location = val),
              ),
              _permissionRow(
                title: "Camera Access",
                icon: Icons.photo_camera_outlined,
                label: "Allow app to use your camera for calls",
                value: _camera,
                onChanged: (v) => _toggle(Permission.camera, v, (val) => _camera = val),
              ),
              _permissionRow(
                title: "Microphone Access",
                icon: Icons.mic_none_outlined,
                label: "Allow app to use your microphone",
                value: _microphone,
                onChanged: (v) => _toggle(Permission.microphone, v, (val) => _microphone = val),
              ),
              _permissionRow(
                title: "Notifications",
                icon: Icons.notifications_none_outlined,
                label: "Allow app to send notifications",
                value: _notifications,
                onChanged: (v) => _toggle(Permission.notification, v, (val) => _notifications = val),
              ),
              const SizedBox(height: 15),
              // All three are plain green text links, matching the Figma
              // screenshot exactly.
              _textLink("Open System Settings", openAppSettings),
              _textLink("Refresh Status", _loadStatuses),
              _textLink(
                "Contact Support",
                () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Contact Support isn't available yet")),
                ),
              ),
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
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
