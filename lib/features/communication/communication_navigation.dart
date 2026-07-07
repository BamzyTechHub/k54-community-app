import 'package:flutter/material.dart';
import 'package:k54_mobile/features/messaging/screens/messages_page.dart';
import 'package:k54_mobile/features/messaging/widgets/unread_badge.dart';
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF008000),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const UnreadBadge(child: Icon(Icons.message_outlined)),
            activeIcon: const UnreadBadge(child: Icon(Icons.message)),
            label: "Messages",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: "Friends",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: "Groups",
          ),
        ],
      ),
    );
  }
}