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
      backgroundColor: Colors.white,
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

  Widget _tabSegment({required int index, required String label, required Widget icon}) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => currentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.tabSelectedFill : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.tabSelectedBorder : AppColors.tabSelectedFill,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.jetBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
