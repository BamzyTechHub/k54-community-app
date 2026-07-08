import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/features/home/screens/home_page.dart';
import 'package:k54_mobile/features/ai/screens/ai_page.dart';
import 'package:k54_mobile/features/members/screens/members_page.dart';
import 'package:k54_mobile/features/groups/screens/groups_page.dart';
import 'package:k54_mobile/features/courses/screens/courses_page.dart';

/// Matches the K54 Figma file's main bottom nav exactly (measured via the
/// Figma REST API on the "MEMBERS" frame, node 55:1914, "TAB MENU"
/// component, 2026-07-08): every icon/label uses the same brand gradient
/// regardless of selection - only a colored top border marks the active
/// tab, there's no icon-color swap like a stock BottomNavigationBar.
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
            return Expanded(
              child: GestureDetector(
                onTap: () => _navigate(context, index),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isSelected ? const Color(0xFF008000) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
                        child: Icon(icon, size: 24, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
