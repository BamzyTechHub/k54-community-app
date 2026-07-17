import 'package:flutter/material.dart';
import 'package:k54_mobile/core/widgets/underline_tab_row.dart';
import 'package:k54_mobile/features/profile/widgets/profile_menu.dart';

/// Corrected 2026-07-18 (second pass) against a fuller set of Figma
/// screenshots: this isn't a static 3-tab row with a separate action
/// menu - it's a single sliding carousel of 9 destinations (Timeline/My
/// Connections/live Video, then Groups/Messages/Courses/Documents/Email
/// Invites/Account Settings from the "..." menu). Only 3 show at once;
/// picking a hidden one from "..." slides it into view (dropping the
/// oldest of the current 3) and its content renders inline in the same
/// scrolling profile page - confirmed by the screenshots showing the
/// visible 3-tab window itself change (e.g. "My Connections | live Video
/// | Groups" becomes "live Video | Groups | Messages" after picking
/// Messages). Account Settings is the one exception - it pushes the real
/// SettingsPage instead of becoming an inline tab, since cramming full
/// account management inline under a scrolling feed isn't reasonable UX
/// and no screenshot shows it any other way. All of that sliding-window
/// state lives in ProfilePage; this widget just renders whatever 3 tabs
/// and active tab it's given.
class ProfileTabs extends StatelessWidget {
  final List<String> visibleTabs;
  final String activeTab;
  final ValueChanged<String> onTabChanged;
  final ValueChanged<String> onMenuPressed;

  const ProfileTabs({
    super.key,
    required this.visibleTabs,
    required this.activeTab,
    required this.onTabChanged,
    required this.onMenuPressed,
  });

  static const baseTabs = ["Timeline", "My Connections", "live Video"];
  static const menuTabs = ["Groups", "Messages", "Courses", "Documents", "Email Invites", "Account Settings"];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = visibleTabs.indexOf(activeTab);
    return Row(
      children: [
        Expanded(
          child: UnderlineTabRow(
            tabs: visibleTabs,
            selectedIndex: selectedIndex,
            onChanged: (index) => onTabChanged(visibleTabs[index]),
          ),
        ),
        ProfileMenu(selectedLabel: activeTab, onSelected: onMenuPressed),
      ],
    );
  }
}
