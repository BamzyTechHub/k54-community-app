import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/features/profile/models/account_settings_field.dart';
import 'package:k54_mobile/features/profile/repositories/account_settings_repository.dart';

/// Matches the Notifications Settings Figma frame exactly (node
/// 482:1466, pulled via the REST API 2026-07-16).
///
/// Four of these toggles are now real, confirmed live 2026-07-20 against
/// `/buddyboss/v1/account-settings/notifications` (test-and-revert on
/// this app's own account) - the real API exposes ~20 individual
/// notification-type toggles (each with separate Email/Web sub-keys),
/// which this bundles under the Figma design's 4 broader category rows:
/// General (the real API's own literal master switch), Messages
/// (Better Messages' new-message notification), Likes and Comments
/// (activity/post comment-reply types), Activity (following/mentions),
/// Group (every `bb_groups_*`/`bb_forums_*` type together, since forums
/// live inside groups). Sound/Vibration/DND/Mute/location-based rows have
/// no website equivalent at all (they're inherently device/app-level
/// concepts a website has no concept of) - those stay honest local-only
/// state, same as before.
class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  static const _nav = "notifications";

  // Real keys behind each bundled toggle - see class doc comment for the
  // Figma-category-to-real-key mapping reasoning. Each bundle's email+web
  // pair are always set together.
  static const _generalKeys = ["enable_notification", "enable_notification_web"];
  static const _messageKeys = ["better_messages_new_message", "better_messages_new_message_web"];
  static const _likesCommentsKeys = [
    "bb_activity_comment", "bb_activity_comment_web",
    "bb_posts_new_comment_reply", "bb_posts_new_comment_reply_web",
  ];
  static const _activityKeys = [
    "bb_activity_following_post", "bb_activity_following_post_web",
    "bb_following_new", "bb_following_new_web",
    "bb_new_mention", "bb_new_mention_web",
    "bb_connections_new_request", "bb_connections_new_request_web",
    "bb_connections_request_accepted", "bb_connections_request_accepted_web",
  ];
  static const _groupKeys = [
    "bb_groups_details_updated", "bb_groups_details_updated_web",
    "bb_groups_promoted", "bb_groups_promoted_web",
    "bb_groups_new_invite", "bb_groups_new_invite_web",
    "bb_groups_new_request", "bb_groups_new_request_web",
    "bb_groups_request_accepted", "bb_groups_request_accepted_web",
    "bb_groups_request_rejected", "bb_groups_request_rejected_web",
    "bb_groups_subscribed_activity", "bb_groups_subscribed_activity_web",
    "bb_groups_subscribed_discussion", "bb_groups_subscribed_discussion_web",
    "bb_forums_subscribed_discussion", "bb_forums_subscribed_discussion_web",
    "bb_forums_subscribed_reply", "bb_forums_subscribed_reply_web",
  ];

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

  bool _loading = true;
  final Set<String> _savingBundles = {};

  static const _muteOptions = ["1 Hour", "2 Hours", "Until I Turn it Off"];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final fields = await AccountSettingsRepository.instance.getSection(_nav);
      final values = <String, String>{};
      void collect(List<AccountSettingsField> items) {
        for (final f in items) {
          if (f.name.isNotEmpty) values[f.name] = f.value;
          collect(f.subfields);
        }
      }
      collect(fields);

      bool allYes(List<String> keys) => keys.every((k) => values[k] != "no");

      if (!mounted) return;
      setState(() {
        _general = allYes(_generalKeys);
        _messages = allYes(_messageKeys);
        _likesComments = allYes(_likesCommentsKeys);
        _activity = allYes(_activityKeys);
        _groups = allYes(_groupKeys);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveBundle(String bundleId, List<String> keys, bool enabled) async {
    setState(() => _savingBundles.add(bundleId));
    try {
      final updates = {for (final key in keys) key: enabled ? "yes" : "no"};
      await AccountSettingsRepository.instance.saveSection(_nav, updates);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't update notification setting: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _savingBundles.remove(bundleId));
    }
  }

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
      const SnackBar(
        content: Text(
          "General/Message/Likes and Comments/Activity/Group notifications save "
          "instantly and are already synced. Sound, Vibration, Do Not Disturb, Mute, "
          "and location-based notifications are device-only settings with no website "
          "equivalent, so they aren't saved anywhere.",
        ),
        duration: Duration(seconds: 5),
      ),
    );
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
                    "Notifications Settings",
                    style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(color: AppColors.green),
                ),
              _toggleRow(
                "General Notifications",
                "General Notifications",
                _general,
                (v) {
                  setState(() => _general = v);
                  _saveBundle("general", _generalKeys, v);
                },
                saving: _savingBundles.contains("general"),
              ),
              _toggleRow(
                "Smart Push Notifications",
                "Enable notifications based on your preferences and recent activity.",
                _smartPush,
                (v) => setState(() => _smartPush = v),
              ),
              _toggleRow(
                "Message Notifications",
                null,
                _messages,
                (v) {
                  setState(() => _messages = v);
                  _saveBundle("messages", _messageKeys, v);
                },
                saving: _savingBundles.contains("messages"),
              ),
              _toggleRow(
                "Likes and Comments",
                null,
                _likesComments,
                (v) {
                  setState(() => _likesComments = v);
                  _saveBundle("likesComments", _likesCommentsKeys, v);
                },
                saving: _savingBundles.contains("likesComments"),
              ),
              _toggleRow(
                "Activity Notifications",
                null,
                _activity,
                (v) {
                  setState(() => _activity = v);
                  _saveBundle("activity", _activityKeys, v);
                },
                saving: _savingBundles.contains("activity"),
              ),
              _toggleRow(
                "Group Notifications",
                null,
                _groups,
                (v) {
                  setState(() => _groups = v);
                  _saveBundle("groups", _groupKeys, v);
                },
                saving: _savingBundles.contains("groups"),
              ),
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

  Widget _toggleRow(String title, String? subtitle, bool value, ValueChanged<bool> onChanged, {bool saving = false}) {
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
          if (saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)),
            )
          else
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
