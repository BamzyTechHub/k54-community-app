import 'package:flutter/material.dart';
import 'package:k54_mobile/features/profile/screens/profile_page.dart';
import 'package:k54_mobile/features/activity/screens/timeline_page.dart';
import 'package:k54_mobile/features/communication/communication_navigation.dart';
import 'package:k54_mobile/features/activity/screens/create_post_page.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';
import 'package:k54_mobile/features/notifications/screens/notifications_page.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
import 'package:k54_mobile/features/messaging/widgets/unread_badge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  // Stable key so the feed widget isn't torn down and remounted on every
  // HomePage rebuild (it previously used ValueKey(DateTime.now()...),
  // which forced a full remount + refetch on every rebuild).
  final GlobalKey _timelineKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Warm the unread-messages badge so it's already correct the moment
    // the home page renders, without requiring the user to open Messages.
    _warmUnreadBadge();
  }

  Future<void> _warmUnreadBadge() async {
    try {
      await MessagingRepository.instance.refreshThreads();
    } catch (_) {
      // Non-fatal — badge just stays at 0 until the next successful refresh.
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
  backgroundColor: Colors.white,

 bottomNavigationBar: const K54BottomNavigation(
  currentIndex: 0,
),

  body: SafeArea(

        child: Column(

          children: [

            // Header
            Padding(

              padding: const EdgeInsets.all(15),


              child: Row(

                children: [

                  GestureDetector(
  onTap: () {

    Navigator.push(
      context,
      MaterialPageRoute(
       builder: (context) => ProfilePage(),
      ),
    );

  },

  child: const CircleAvatar(
    radius: 22,
    backgroundColor: Colors.green,
    child: Icon(
      Icons.person,
      color: Colors.white,
    ),
  ),
),


                  const SizedBox(width: 10),


                  // Search Bar
                  Expanded(

                    child: Container(

                      height: 45,


                      decoration: BoxDecoration(

                        color: Colors.grey.shade200,

                        borderRadius: BorderRadius.circular(25),

                      ),


                      child: const TextField(

                        decoration: InputDecoration(

                          hintText: "Search",

                          prefixIcon: Icon(Icons.search),

                          border: InputBorder.none,

                        ),

                      ),

                    ),

                  ),


                  const SizedBox(width: 10),


                 // Create Post
IconButton(

  onPressed: () async {

    final created = await Navigator.push<bool>(
  context,
  MaterialPageRoute(
    builder: (_) => const CreatePostPage(),
  ),
);

if (created == true && mounted) {
  setState(() {});
}
  },

  icon: const Icon(

    Icons.add_box_outlined,

    size: 28,

  ),

),

// Notifications
IconButton(

  onPressed: () {

    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (context) =>
            const NotificationsPage(),

      ),

    );

  },

  icon: const Icon(

    Icons.notifications_outlined,

    size: 28,

  ),

),

// Messages
IconButton(

  onPressed: () {

    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (context) =>
            const CommunicationNavigation(),

      ),

    );

  },

  icon: const UnreadBadge(
    child: Icon(
      Icons.chat_bubble_outline,
      size: 28,
    ),
  ),

),

IconButton(

  onPressed: () {

    // Marketplace page coming later

  },

  icon: const Icon(

    Icons.shopping_bag_outlined,

    size: 28,

  ),

),
                ],

              ),

            ),


            // Feed
             Expanded(
  child: TimelinePage(
    key: _timelineKey,
  ),
),

          ],

        ),

      ),

    );

  }

}