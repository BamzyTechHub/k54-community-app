import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/features/home/screens/home_page.dart';
import 'package:k54_mobile/features/ai/screens/ai_page.dart';
import 'package:k54_mobile/features/members/screens/members_page.dart';
import 'package:k54_mobile/features/groups/screens/groups_page.dart';
import 'package:k54_mobile/features/courses/screens/courses_page.dart';

/// Matches the K54 HOME PAGE frame (node 571:714, "TAB MENU"). Active
/// tab: icon+label use the brand gradient (ShaderMask), with a thin
/// gradient bar along the TOP edge only. Inactive tabs: icon+label solid
/// #B4D69E, no border. Corrected 2026-07-17 against a real device
/// screenshot the user sent: the raw JSON's `stroke=GRADIENT_LINEAR` on
/// the active cell was previously read as a full 4-side border box - the
/// actual rendered design only shows that stroke along the top edge, not
/// wrapping the whole cell.
class K54BottomNavigation extends StatelessWidget {
  final int currentIndex;

  const K54BottomNavigation({super.key, required this.currentIndex});

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const AiPage();
        break;
      case 2:
        page = const MembersPage();
        break;
      case 3:
        page = const GroupsPage();
        break;
      case 4:
        page = const CoursesPage();
        break;
      default:
        page = const HomePage();
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home, "Home"),
      (Icons.auto_awesome, "AI Assistant"),
      (Icons.public, "Members"),
      (Icons.groups, "Groups"),
      (Icons.menu_book, "Courses"),
    ];

    return SafeArea(
      child: Container(
        color: Colors.white,
        height: 56,
        child: Row(
          children: List.generate(items.length, (index) {
            final isSelected = index == currentIndex;
            final (icon, label) = items[index];

            final cell = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 2px gradient bar along the top edge only - was a full
                // box border wrapping the whole cell before this was
                // corrected against a real screenshot.
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.brandGradient : null,
                  ),
                ),
                const SizedBox(height: 6),
                isSelected
                    ? ShaderMask(
                        shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
                        child: Icon(icon, size: 24, color: Colors.white),
                      )
                    : Icon(icon, size: 24, color: AppColors.buttonRegularBg),
                const SizedBox(height: 4),
                isSelected
                    ? ShaderMask(
                        shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                        ),
                      )
                    : Text(
                        label,
                        style: GoogleFonts.poppins(fontSize: 10, color: AppColors.buttonRegularBg),
                      ),
              ],
            );

            return Expanded(
              child: GestureDetector(
                onTap: () => _navigate(context, index),
                child: cell,
              ),
            );
          }),
        ),
      ),
    );
  }
}
