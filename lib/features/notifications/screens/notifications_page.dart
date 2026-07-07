import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {

  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();

}

class _NotificationsPageState
    extends State<NotificationsPage> {

 final List<Map<String, dynamic>> notifications = [

  {
    "title": "Cecilia liked your post",
    "time": "2 min ago",
    "icon": Icons.favorite,
    "color": Colors.red,
    "isRead": false,
  },

  {
    "title": "Dan sent you a connection request",
    "time": "15 min ago",
    "icon": Icons.person_add,
    "color": Colors.green,
    "isRead": false,
  },

  {
    "title": "Michael commented on your post",
    "time": "1 hour ago",
    "icon": Icons.chat_bubble,
    "color": Colors.blue,
    "isRead": true,
  },

  {
    "title": "New course available",
    "time": "3 hours ago",
    "icon": Icons.school,
    "color": Colors.orange,
    "isRead": true,
  },

  {
    "title": "Welcome to K54 Community",
    "time": "1 day ago",
    "icon": Icons.celebration,
    "color": Colors.purple,
    "isRead": true,
  },

];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),

          child: Column(

            children: [

              // =====================
              // Header
              // =====================

              Row(

  children: [

    IconButton(

      onPressed: () {

        Navigator.pop(context);

      },

      icon: const Icon(
        Icons.arrow_back,
      ),

    ),

    const SizedBox(width: 10),

    const Text(

      "Notifications",

      style: TextStyle(

        fontSize: 24,

        fontWeight: FontWeight.bold,

      ),

    ),

    const Spacer(),

    TextButton(

      onPressed: () {

        setState(() {

          for (var notification
              in notifications) {

            notification["isRead"] = true;

          }

        });

      },

      child: const Text(
        "Mark all read",
      ),

    ),

  ],

),
         const SizedBox(height: 20),
         Expanded(

  child: notifications.isEmpty

      ? const Center(

          child: Text(

            "No notifications",

            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),

          ),

        )

      : ListView.builder(

          itemCount: notifications.length,

          itemBuilder: (context, index) {

            final notification =
                notifications[index];

            return InkWell(

              onTap: () {

                setState(() {

                  notification["isRead"] =
                      true;

                });

              },

              child: Container(

                margin: const EdgeInsets.only(
                  bottom: 12,
                ),

                padding:
                    const EdgeInsets.all(15),

                decoration: BoxDecoration(

                  color:
                      notification["isRead"]
                          ? const Color(
                              0xFFF5EFD9)
                          : const Color(
                              0xFFE8F5E9),

                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),

                ),

                child: Row(

                  children: [

                    CircleAvatar(

                      backgroundColor:
                          notification["color"],

                      child: Icon(

                        notification["icon"],

                        color: Colors.white,

                      ),

                    ),

                    const SizedBox(
                      width: 15,
                    ),

                    Expanded(

                      child: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          Text(

                            notification[
                                "title"],

                            style:
                                const TextStyle(

                              fontWeight:
                                  FontWeight
                                      .bold,

                            ),

                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(

                            notification[
                                "time"],

                            style:
                                const TextStyle(

                              color:
                                  Colors.grey,

                            ),

                          ),

                        ],

                      ),

                    ),

                    if (!notification["isRead"])

                      Container(

                        width: 10,

                        height: 10,

                        decoration:
                            const BoxDecoration(

                          color: Colors.green,

                          shape:
                              BoxShape.circle,

                        ),

                      ),

                  ],

                ),

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