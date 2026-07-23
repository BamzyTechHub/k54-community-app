import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/features/messaging/screens/messages_page.dart';
import 'package:k54_mobile/core/widgets/unread_badge.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
import 'package:k54_mobile/features/friends/screens/friends_page.dart';
import 'package:k54_mobile/features/groups/screens/groups_page.dart';

class CommunicationNavigation extends StatefulWidget {
  const CommunicationNavigation({super.key});

  @override
  State<CommunicationNavigation> createState() => _CommunicationNavigationState();
}

class _CommunicationNavigationState extends State<CommunicationNavigation> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const MessagesPage(),
    const FriendsPage(),
    const GroupsPage(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: pages[currentIndex],
      bottomNavigationBar: SafeArea(
        child: Row(
          children: [
            _tabSegment(
              index: 0,
              label: "Messages",
              icon: UnreadBadge(
                count: MessagingRepository.instance.unreadCount,
                child: const Icon(Icons.chat_bubble_outline, size: 14),
              ),
            ),
            _tabSegment(
              index: 1,
              label: "Friends",
              icon: const Icon(Icons.people_alt_outlined, size: 14),
            ),
            _tabSegment(
              index: 2,
              label: "Groups",
              icon: const Icon(Icons.groups_outlined, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Corrected 2026-07-18 against a real device screenshot the user sent:
  // the active tab is a light-green highlight (#E8EFE8 fill) with a
  // top-edge-only green line and solid dark-olive-green icon/text - NOT
  // the full 4-side box border + rainbow brand-gradient text this used to
  // have. That was the same JSON-stroke misreading already caught and
  // fixed on K54BottomNavigation (a `stroke` value on the active cell
  // reads as a full border in the raw JSON but only renders as a top
  // line in the real app) - this sub-tab bar had the identical bug and
  // was missed in that earlier pass.
  Widget _tabSegment({required int index, required String label, required Widget icon}) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.green : const Color(0xFFB4D69E);
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconTheme.merge(
          data: IconThemeData(color: color),
          child: icon,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: color,
          ),
        ),
      ],
    );

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => currentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8EFE8) : AppColors.transparent,
            border: isSelected
                ? const Border(top: BorderSide(color: AppColors.green, width: 2))
                : null,
          ),
          child: content,
        ),
      ),
    );
  }
}