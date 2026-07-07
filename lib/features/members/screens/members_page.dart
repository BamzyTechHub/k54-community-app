import 'package:flutter/material.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}


class _MembersPageState extends State<MembersPage> {

  // Selected Tab
  int selectedTab = 0;


  // Member Tabs
  final List<String> tabs = [
    "All Members",
    "My Connections",
    "Following",
    "Followers",
  ];


  // Dummy Members Data
  final List<Map<String, String>> members = [

    {
      "name": "EVELYN",
      "joined": "Joined Feb 2026",
      "status": "Active",
      "followers": "39 Followers",
      "image":
          "assets/images/member1.png",
    },

    {
      "name": "DANIEL",
      "joined": "Joined Jan 2026",
      "status": "Active",
      "followers": "102 Followers",
      "image":
          "assets/images/member2.png",
    },

    {
      "name": "MICHAEL",
      "joined": "Joined Mar 2026",
      "status": "Online",
      "followers": "85 Followers",
      "image":
          "assets/images/member3.png",
    },

  ];


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,


      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // Header Row

              Row(

                children: [

                  const Text(

                    "Members",

                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),

                  ),

                  const Spacer(),


                  IconButton(

                    onPressed: () {

                      // Search filter later

                    },

                    icon: const Icon(
                      Icons.filter_alt_outlined,
                      size: 28,
                    ),

                  ),

                ],

              ),


              const SizedBox(height: 15),


              // Search Bar

              Container(

                height: 45,

                decoration: BoxDecoration(

                  color: const Color(0xFFF3EFD9),

                  borderRadius:
                      BorderRadius.circular(25),

                ),

                child: const TextField(

                  decoration: InputDecoration(

                    hintText:
                        "Search members",

                    prefixIcon: Icon(
                      Icons.search,
                    ),

                    border: InputBorder.none,

                  ),

                ),

              ),


              const SizedBox(height: 20),


              // Part 2 continues here
              // Member Tabs

SizedBox(

  height: 40,

  child: ListView.builder(

    scrollDirection: Axis.horizontal,

    itemCount: tabs.length,

    itemBuilder: (context, index) {

      bool isSelected = selectedTab == index;

      return GestureDetector(

        onTap: () {

          setState(() {

            selectedTab = index;

          });

        },

        child: Container(

          margin: const EdgeInsets.only(right: 12),

          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 8,
          ),

          decoration: BoxDecoration(

            border: Border(

              bottom: BorderSide(

                color: isSelected
                    ? const Color(0xFF008000)
                    : Colors.transparent,

                width: 3,

              ),

            ),

          ),

          child: Text(

            tabs[index],

            style: TextStyle(

              color: isSelected
                  ? const Color(0xFF008000)
                  : Colors.grey,

              fontWeight: FontWeight.bold,

            ),

          ),

        ),

      );

    },

  ),

),


const SizedBox(height: 15),


// Members Count and Controls

Row(

  children: [

    const Text(

      "97 Members",

      style: TextStyle(

        fontSize: 16,

        fontWeight: FontWeight.bold,

      ),

    ),


    const Spacer(),


    Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),

      decoration: BoxDecoration(

        border: Border.all(
          color: Colors.grey.shade300,
        ),

        borderRadius: BorderRadius.circular(8),

      ),

      child: const Row(

        children: [

          Text(
            "Recently Active",
            style: TextStyle(
              fontSize: 12,
            ),
          ),

          SizedBox(width: 5),

          Icon(
            Icons.keyboard_arrow_down,
            size: 18,
          ),

        ],

      ),

    ),


    const SizedBox(width: 10),


    const Icon(
      Icons.grid_view,
      color: Colors.grey,
    ),

  ],

),


const SizedBox(height: 15),


// Members List

Expanded(

  child: ListView.builder(

    itemCount: members.length,

    itemBuilder: (context, index) {

      final member = members[index];


      return Container(

        margin: const EdgeInsets.only(
          bottom: 18,
        ),

        decoration: BoxDecoration(

          color: const Color(0xFFF5EFD9),

          borderRadius: BorderRadius.circular(20),

        ),

        padding: const EdgeInsets.all(15),


        child: Column(

          children: [

            // Member Image

            Stack(

              children: [

                CircleAvatar(

                  radius: 35,

                  backgroundImage: AssetImage(
                    member["image"]!,
                  ),

                ),


                Positioned(

                  right: 3,

                  bottom: 3,

                  child: Container(

                    width: 12,

                    height: 12,

                    decoration: const BoxDecoration(

                      color: Colors.green,

                      shape: BoxShape.circle,

                    ),

                  ),

                ),

              ],

            ),


            const SizedBox(height: 12),


            Text(

              member["name"]!,

              style: const TextStyle(

                fontSize: 20,

                fontWeight: FontWeight.bold,

              ),

            ),


            const SizedBox(height: 5),


            Text(

              "${member["joined"]} • ${member["status"]}",

              style: const TextStyle(

                color: Colors.grey,

              ),

            ),


            const SizedBox(height: 5),


            Text(

              member["followers"]!,

              style: const TextStyle(

                color: Color(0xFF008000),

                fontWeight: FontWeight.w600,

              ),

            ),


            const SizedBox(height: 15),


            // Part 3 continues here
            // Action Buttons

            Row(

              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,

              children: [

                IconButton(

                  onPressed: () {

                    // Follow action

                  },

                  icon: const Icon(
                    Icons.person_add_alt,
                    color: Color(0xFF008000),
                  ),

                ),


                IconButton(

                  onPressed: () {

                    // Message action

                  },

                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.black54,
                  ),

                ),


                IconButton(

                  onPressed: () {

                    // Call action

                  },

                  icon: const Icon(
                    Icons.call_outlined,
                    color: Colors.black54,
                  ),

                ),


                IconButton(

                  onPressed: () {

                    // Video call action

                  },

                  icon: const Icon(
                    Icons.videocam_outlined,
                    color: Colors.black54,
                  ),

                ),

              ],

            ),

          ],

        ),

      );

    },

  ),

),

          ],

        ),

      ),

      ),

      bottomNavigationBar: const K54BottomNavigation(
        currentIndex: 2,
      ),

    );

  }

}