import 'package:flutter/material.dart';


class FriendsPage extends StatefulWidget {

  const FriendsPage({super.key});


  @override
  State<FriendsPage> createState() =>
      _FriendsPageState();

}


class _FriendsPageState extends State<FriendsPage> {


  // Dummy Friends Data
  final List<Map<String, String>> friends = [

    {
      "name": "Cecilia",
      "image": "assets/images/member1.png",
      "status": "online",
    },

    {
      "name": "Dan",
      "image": "assets/images/member2.png",
      "status": "online",
    },

    {
      "name": "Linda",
      "image": "assets/images/member3.png",
      "status": "online",
    },

    {
      "name": "Martha",
      "image": "assets/images/member1.png",
      "status": "offline",
    },

    {
      "name": "Priya",
      "image": "assets/images/member2.png",
      "status": "online",
    },

    {
      "name": "Miriam",
      "image": "assets/images/member3.png",
      "status": "online",
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

                    "Friends",

                    style: TextStyle(

                      fontSize: 28,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  const Spacer(),
                  // Search Icon
                  IconButton(

                    onPressed: () {

                      // Search friends later

                    },

                    icon: const Icon(
                      Icons.search,
                      size: 28,
                    ),

                  ),


                  // Video Call Icon
                  IconButton(

                    onPressed: () {

                      // Group video call later

                    },

                    icon: const Icon(
                      Icons.videocam_outlined,
                      size: 28,
                    ),

                  ),


                  // Phone Call Icon
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
              // Friends List
              // =====================

              Expanded(

                child: ListView.builder(

                  itemCount: friends.length,

                  itemBuilder: (context, index) {


                    final friend = friends[index];


                    return Container(

                      margin: const EdgeInsets.only(
                        bottom: 15,
                      ),

                      child: Row(

                        children: [

                          // Profile Image
                          Stack(

                            children: [

                              CircleAvatar(

                                radius: 30,

                                backgroundImage: AssetImage(
                                  friend["image"]!,
                                ),

                              ),
                              // Online Indicator
                              if (friend["status"] == "online")

                                Positioned(

                                  right: 2,

                                  bottom: 2,

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

                          const SizedBox(width: 15),


                          // Friend Name & Status
                          Expanded(

                            child: Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [

                                Text(

                                  friend["name"]!,

                                  style: const TextStyle(

                                    fontSize: 18,

                                    fontWeight: FontWeight.bold,

                                  ),

                                ),

                                const SizedBox(height: 5),


                                Text(

                                  friend["status"] == "online"
                                      ? "Online"
                                      : "Offline",

                                  style: TextStyle(

                                    color:
                                        friend["status"] == "online"
                                            ? const Color(0xFF008000)
                                            : Colors.grey,

                                    fontWeight: FontWeight.w500,

                                  ),

                                ),

                              ],

                            ),

                          ),


                          // Add Friend Button
                          IconButton(

                            onPressed: () {

                              // Add friend action later

                            },

                            icon: const Icon(

                              Icons.person_add_alt,

                              color: Color(0xFF008000),

                            ),

                          ),


                          // Voice Call Button
                          IconButton(

                            onPressed: () {

                              // Voice call action later

                            },

                            icon: const Icon(

                              Icons.call_outlined,

                              color: Colors.black54,

                            ),

                          ),


                          // Video Call Button
                          IconButton(

                            onPressed: () {

                              // Video call action later

                            },

                            icon: const Icon(

                              Icons.videocam_outlined,

                              color: Colors.black54,

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