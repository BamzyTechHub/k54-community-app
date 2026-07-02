import 'package:flutter/material.dart';
import 'package:k54_mobile/Profile/profile_page.dart';
import '../Profile/timeline_page.dart';
import '../communication/communication_navigation.dart';
import '../posts/create_post_page.dart';
import '../widgets/bottom_navigation.dart';
import '../notifications/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
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

  onPressed: () {

    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (context) =>
            const CreatePostPage(),

      ),

    );

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

  icon: const Icon(

    Icons.chat_bubble_outline,

    size: 28,

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
  child: TimelinePage(),
),

          ],

        ),

      ),

    );

  }

}