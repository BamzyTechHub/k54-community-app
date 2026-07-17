import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';

/// Shared single-choice picker page - matches the Figma "Profile
/// Visibility screen" / "Profile Picture Visibility screen" / "Who Can
/// Message Me Screen" / "Who Can Add Me To Groups Screen" pattern
/// exactly: header, a green subtitle, then a plain radio list with no
/// save button - tapping an option selects it and returns immediately
/// (there's nothing to "save" separately, same as the live site's own
/// equivalent single-choice settings). Same "no confirmed privacy
/// REST endpoint" limitation as PrivacySettingsPage itself - the
/// selection only updates local state on the parent page, not persisted
/// anywhere real.
class RadioSelectPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> options;
  final String selectedValue;

  const RadioSelectPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selectedValue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                  const SizedBox(width: 6),
                  Text(title, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack)),
                ],
              ),
              const SizedBox(height: 16),
              Text(subtitle, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.green)),
              const SizedBox(height: 12),
              for (final option in options)
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: option,
                  groupValue: selectedValue,
                  activeColor: AppColors.green,
                  title: Text(option, style: GoogleFonts.lato(fontSize: 15, color: AppColors.jetBlack)),
                  onChanged: (v) => Navigator.pop(context, v),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The one sub-page with two radio groups on one screen (visibility +
/// "who can see when I'm online"), so it doesn't fit RadioSelectPage's
/// single-group shape.
class LastSeenPage extends StatefulWidget {
  final String initialLastSeen;
  final String initialOnlineVisibility;

  const LastSeenPage({super.key, required this.initialLastSeen, required this.initialOnlineVisibility});

  @override
  State<LastSeenPage> createState() => _LastSeenPageState();
}

class _LastSeenPageState extends State<LastSeenPage> {
  late String _lastSeen = widget.initialLastSeen;
  late String _onlineVisibility = widget.initialOnlineVisibility;

  static const _lastSeenOptions = ["Everyone", "My Contacts", "Nobody"];
  static const _onlineOptions = ["Everyone", "Same as last seen"];

  void _done() {
    Navigator.pop(context, (lastSeen: _lastSeen, online: _onlineVisibility));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _done();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(onPressed: _done, icon: const Icon(Icons.arrow_back)),
                    const SizedBox(width: 6),
                    Text("Last Seen", style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack)),
                  ],
                ),
                const SizedBox(height: 16),
                Text("Who can see my last seen",
                    style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.green)),
                const SizedBox(height: 8),
                for (final option in _lastSeenOptions)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: option,
                    groupValue: _lastSeen,
                    activeColor: AppColors.green,
                    title: Text(option, style: GoogleFonts.lato(fontSize: 15, color: AppColors.jetBlack)),
                    onChanged: (v) => setState(() => _lastSeen = v!),
                  ),
                const SizedBox(height: 16),
                Text("who can see when I'm online",
                    style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.jetBlack)),
                const SizedBox(height: 8),
                for (final option in _onlineOptions)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: option,
                    groupValue: _onlineVisibility,
                    activeColor: AppColors.green,
                    title: Text(option, style: GoogleFonts.lato(fontSize: 15, color: AppColors.jetBlack)),
                    onChanged: (v) => setState(() => _onlineVisibility = v!),
                  ),
                const SizedBox(height: 16),
                Text(
                  "If you don't share when you were last seen or online, you won't be able to see when other people "
                  "were last seen or online.",
                  style: GoogleFonts.lato(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
