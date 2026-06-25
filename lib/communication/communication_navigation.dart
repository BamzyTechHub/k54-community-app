import 'package:flutter/material.dart';
import '../communication/messages_page.dart';
import '../communication/friends_page.dart';
import '../communication/groups_page.dart';

class CommunicationNavigation extends StatefulWidget {

  const CommunicationNavigation({
    super.key,
  });


  @override
  State<CommunicationNavigation> createState() =>
      _CommunicationNavigationState();
}


class _CommunicationNavigationState
    extends State<CommunicationNavigation> {


  // Current selected tab
  int currentIndex = 0;


  // Communication pages
  final List<Widget> pages = [

    const MessagesPage(),

    const FriendsPage(),

    const GroupsPage(),

  ];


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,


      // Display current page
      body: pages[currentIndex],
      // Communication Bottom Navigation
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


        items: const [

          BottomNavigationBarItem(

            icon: Icon(
              Icons.message_outlined,
            ),

            activeIcon: Icon(
              Icons.message,
            ),

            label: "Messages",

          ),


          BottomNavigationBarItem(

            icon: Icon(
              Icons.people_outline,
            ),

            activeIcon: Icon(
              Icons.people,
            ),

            label: "Friends",

          ),


          BottomNavigationBarItem(

            icon: Icon(
              Icons.groups_outlined,
            ),

            activeIcon: Icon(
              Icons.groups,
            ),

            label: "Groups",

          ),

        ],

      ),

    );

  }
    }