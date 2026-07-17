import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';

/// Matches the Notifications Settings Figma frame exactly (node
/// 482:1466, pulled via the REST API 2026-07-16). All toggles/dropdown
/// are real, interactive local UI state - there's no confirmed
/// notification-preferences backend or local persistence wired up, so
/// Save Changes says so explicitly instead of pretending the choices
/// were saved anywhere.
class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _general = true;
  bool _smartPush = true;
  bool _messages = true;
  bool _likesComments = true;
  bool _activity = true;
  bool _groups = true;
  bool _sound = true;
  bool _vibration = true;
  bool _doNotDisturb = false;
  String _muteFor = "Until I Turn it Off";
  bool _eventReminders = true;
  bool _specialOffers = false;
  bool _checkInReminders = true;

  static const _muteOptions = ["1 Hour", "2 Hours", "Until I Turn it Off"];

  Future<void> _pickMuteDuration() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Mute Notifications for:", style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _muteOptions
              .map((option) => RadioListTile<String>(
                    value: option,
                    groupValue: _muteFor,
                    activeColor: AppColors.green,
                    title: Text(option, style: GoogleFonts.lato(fontSize: 15)),
                    onChanged: (v) => Navigator.pop(dialogContext, v),
                  ))
              .toList(),
        ),
      ),
    );
    if (selected != null) setState(() => _muteFor = selected);
  }

  void _notAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saving notification settings isn't available yet - no backend is configured.")),
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
                    "Notifications Settings",
                    style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _toggleRow("General Notifications", "General Notifications", _general, (v) => setState(() => _general = v)),
              _toggleRow(
                "Smart Push Notifications",
                "Enable notifications based on your preferences and recent activity.",
                _smartPush,
                (v) => setState(() => _smartPush = v),
              ),
              _toggleRow("Message Notifications", null, _messages, (v) => setState(() => _messages = v)),
              _toggleRow("Likes and Comments", null, _likesComments, (v) => setState(() => _likesComments = v)),
              _toggleRow("Activity Notifications", null, _activity, (v) => setState(() => _activity = v)),
              _toggleRow("Group Notifications", null, _groups, (v) => setState(() => _groups = v)),
              const SizedBox(height: 8),
              Text("Notification Sound and Vibration",
                  style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.jetBlack)),
              const SizedBox(height: 12),
              _toggleRow("Sound Notifications", null, _sound, (v) => setState(() => _sound = v)),
              _toggleRow("Vibration Notifications", null, _vibration, (v) => setState(() => _vibration = v)),
              _toggleRow("Do Not Disturb Mode", null, _doNotDisturb, (v) => setState(() => _doNotDisturb = v)),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: _pickMuteDuration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mute Notifications for:",
                          style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.jetBlack)),
                      Row(
                        children: [
                          Text(_muteFor, style: GoogleFonts.lato(fontSize: 16, color: AppColors.jetBlack)),
                          const Icon(Icons.keyboard_arrow_down, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Plain section description, not a toggle - the earlier
              // version combined all three location-based rows into a
              // 4th master toggle that isn't in the Figma design at all,
              // which only shows this as description text above the
              // three real toggles below.
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Location-Based Notifications",
                        style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.jetBlack)),
                    const SizedBox(height: 3),
                    Text(
                      "Enable notifications for events, offers, or alerts when you're near a specific location.",
                      style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF515050)),
                    ),
                  ],
                ),
              ),
              _toggleRow("Event Reminders Near You", null, _eventReminders, (v) => setState(() => _eventReminders = v)),
              _toggleRow("Special Offers and Promotions", null, _specialOffers, (v) => setState(() => _specialOffers = v)),
              _toggleRow("Check-In Reminders", null, _checkInReminders, (v) => setState(() => _checkInReminders = v)),
              const SizedBox(height: 20),
              PrimaryButton(label: "Save Changes", height: 48, onPressed: _notAvailable),
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

  Widget _toggleRow(String title, String? subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.jetBlack)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle, style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF515050))),
                ],
              ],
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
    );
  }
}
