import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';

/// Empty states below match the live site's own profile tabs exactly
/// (fetched directly from k54global.com/members/{user}/documents|quizzes|
/// orders/ - no confirmed backend exists for any of these yet, so there's
/// real content to browse, just the honest empty state the website itself
/// shows). Figma has no design for these tabs at all.

/// Generic empty-state shared by Documents and Quizzes - same shape on
/// the live site, just different copy.
class ProfileEmptyTab extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? extra;

  const ProfileEmptyTab({super.key, required this.icon, required this.message, this.extra});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFD9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.groupMutedText),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.jetBlack),
          ),
          if (extra != null) ...[const SizedBox(height: 16), extra!],
        ],
      ),
    );
  }
}

/// Documents tab: search bar (non-functional - no confirmed document
/// endpoint) + the live site's own "Sorry, no documents were found."
class ProfileDocumentsTab extends StatelessWidget {
  const ProfileDocumentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.groupCardBackground,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 16, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: "Search Documents…",
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.gold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const ProfileEmptyTab(icon: Icons.description_outlined, message: "Sorry, no documents were found."),
      ],
    );
  }
}

/// Orders tab: matches the live site's WooCommerce-flavored empty state
/// exactly ("No orders!" + order-key recovery), not a generic message.
class ProfileOrdersTab extends StatelessWidget {
  const ProfileOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileEmptyTab(
      icon: Icons.receipt_long_outlined,
      message: "No orders!",
      extra: Column(
        children: [
          Text(
            "If you have a valid order key, you can recover it here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Order recovery isn't available yet")),
            ),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.green)),
            child: const Text("Recover"),
          ),
        ],
      ),
    );
  }
}

/// Courses tab: "Enrolled Courses" / "Created Courses" sub-tabs, matching
/// the live site exactly.
class ProfileCoursesTab extends StatefulWidget {
  const ProfileCoursesTab({super.key});

  @override
  State<ProfileCoursesTab> createState() => _ProfileCoursesTabState();
}

class _ProfileCoursesTabState extends State<ProfileCoursesTab> {
  int _subTab = 0;

  @override
  Widget build(BuildContext context) {
    const subTabs = ["Enrolled Courses", "Created Courses"];
    return Column(
      children: [
        Row(
          children: List.generate(subTabs.length, (index) {
            final selected = _subTab == index;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => setState(() => _subTab = index),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: selected ? AppColors.green : Colors.transparent, width: 2),
                    ),
                  ),
                  child: Text(
                    subTabs[index],
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.jetBlack),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        ProfileEmptyTab(
          icon: Icons.school_outlined,
          message: _subTab == 0
              ? "This member has not enrolled in any courses yet!"
              : "This member has not created any courses yet!",
        ),
      ],
    );
  }
}
