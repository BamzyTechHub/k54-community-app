import 'package:flutter/material.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}


class _GroupsPageState extends State<GroupsPage> {


  // Dummy Groups Data
  final List<Map<String, String>> groups = [

    {
      "name": "K54 Business Club",
      "members": "15 Members",
      "image": "assets/images/member1.png",
      "status": "Active",
    },

    {
      "name": "AI Innovation Club",
      "members": "32 Members",
      "image": "assets/images/member2.png",
      "status": "Active",
    },

    {
      "name": "Study Group",
      "members": "8 Members",
      "image": "assets/images/member3.png",
      "status": "New",
    },

    {
      "name": "Church Community",
      "members": "48 Members",
      "image": "assets/images/member1.png",
      "status": "Active",
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

            children: [

              // =====================
              // Header
              // =====================

              Row(

                children: [

                  const Text(

                    "Groups",

                    style: TextStyle(

                      fontSize: 28,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  const Spacer(),
                  // Search Icon
                  IconButton(

                    onPressed: () {

                      // Search groups later

                    },

                    icon: const Icon(
                      Icons.search,
                      size: 28,
                    ),

                  ),


                  // Create Group Icon
                  IconButton(

                    onPressed: () {

                      // Create group later

                    },

                    icon: const Icon(
                      Icons.group_add_outlined,
                      size: 28,
                    ),

                  ),


                  // Call Icon
                  IconButton(

                    onPressed: () {

                      // Group call later

                    },

                    icon: const Icon(
                      Icons.call_outlined,
                      size: 28,
                    ),

                  ),

                ],

              ),


              const SizedBox(height: 20),


              // =====================
              // Groups List
              // =====================

              Expanded(

                child: ListView.builder(

                  itemCount: groups.length,

                  itemBuilder: (context, index) {


                    final group = groups[index];


                    return Container(

                      margin: const EdgeInsets.only(
                        bottom: 15,
                      ),

                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(

                        color: const Color(0xFFF5EFD9),

                        borderRadius:
                            BorderRadius.circular(18),

                      ),

                      child: Row(

                        children: [

                          // Group Image
                          CircleAvatar(

                            radius: 30,

                            backgroundImage: AssetImage(

                              group["image"]!,

                            ),

                          ),


                          const SizedBox(width: 15),


                          // Group Details
                          Expanded(

                            child: Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [
                                // Group Name
                                Text(

                                  group["name"]!,

                                  style: const TextStyle(

                                    fontSize: 18,

                                    fontWeight: FontWeight.bold,

                                  ),

                                ),


                                const SizedBox(height: 5),


                                // Member Count
                                Text(

                                  group["members"]!,

                                  style: const TextStyle(

                                    color: Colors.grey,

                                  ),

                                ),

                              ],

                            ),

                          ),


                          // Status Badge
                          Container(

                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),

                            decoration: BoxDecoration(

                              color: group["status"] == "Active"
                                  ? const Color(0xFF008000)
                                  : const Color(0xFFAB8000),

                              borderRadius:
                                  BorderRadius.circular(20),

                            ),

                            child: Text(

                              group["status"]!,

                              style: const TextStyle(

                                color: Colors.white,

                                fontWeight: FontWeight.bold,

                                fontSize: 12,

                              ),

                            ),

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

    );

  }

}
