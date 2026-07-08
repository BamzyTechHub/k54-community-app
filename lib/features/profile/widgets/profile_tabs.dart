import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/features/profile/widgets/profile_menu.dart';

/// Matches the K54 Figma file's profile tab row exactly (node 289:225
/// "PROFILE PAGE/TIMELINE", rendered 2026-07-08): three tabs plus the
/// "..." overflow menu. The previous implementation had 7 tabs
/// (Timeline/Connections/Live Video/Groups/Messages/Courses/
/// Invitations) that Figma doesn't show at all on this screen.
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

  static const tabs = ["Timeline", "My Connections", "live Video"];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
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
        ProfileMenu(onSelected: onMenuPressed),
      ],
    );
  }
}
