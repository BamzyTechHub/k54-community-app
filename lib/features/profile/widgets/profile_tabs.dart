import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/features/profile/widgets/profile_menu.dart';

/// The first 4 tabs (Timeline/My Connections/live Video/Groups) are
/// confirmed directly from Figma's tab-bar component (node 313:3032,
/// "Frame 2147228207"). The Figma file's per-frame copies of this
/// component drift (the file is a work-in-progress), and the live tab
/// row is meant to be a fuller, scrollable set - so the remaining tabs
/// (Courses/Documents/Quizzes/Orders) are taken from the live site's own
/// confirmed profile nav (k54global.com/members/{user}/), which exposes
/// exactly these sections beyond Groups. The "..." icon stays a separate,
/// fixed account-actions menu (Edit/Email/Password/Settings/Logout), not
/// a tab, and does not scroll with the tab row.
class ProfileTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onMenuPressed;

  const ProfileTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.onMenuPressed,
  });

  static const tabs = [
    "Timeline",
    "My Connections",
    "live Video",
    "Groups",
    "Courses",
    "Documents",
    "Quizzes",
    "Orders",
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(tabs.length, (index) {
                final isSelected = selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => onTabChanged(index),
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? AppColors.green : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        tabs[index],
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.jetBlack),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        ProfileMenu(onSelected: onMenuPressed),
      ],
    );
  }
}
