import 'package:flutter/material.dart';

import '../models/chat_model.dart';
import '../models/friend_model.dart';
import '../models/message_model.dart';

import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}


class _MessagesPageState extends State<MessagesPage> {


  // K54 Chat Data
final List<Chat> chats = [

  Chat(

    id: "chat001",

    friend: Friend(

      id: "user001",

      name: "Cecilia",

      image: "assets/images/member1.png",

      isOnline: true,

    ),

    messages: [

      Message(

        id: "msg001",

        text: "Hey, Check this out",

        time: "10:30 AM",

        isMe: false,

      ),

    ],

  ),

  Chat(

    id: "chat002",

    friend: Friend(

      id: "user002",

      name: "Dan",

      image: "assets/images/member2.png",

      isOnline: true,

    ),

    messages: [

      Message(

        id: "msg002",

        text: "Hey, Check this out",

        time: "11:00 AM",

        isMe: false,

      ),

    ],

  ),


  Chat(

    id: "chat003",

    friend: Friend(

      id: "user003",

      name: "Linda",

      image: "assets/images/member3.png",

      isOnline: true,

    ),

    messages: [

      Message(

        id: "msg003",

        text: "Typing...",

        time: "11:30 AM",

        isMe: false,

      ),

    ],

  ),


  Chat(

    id: "chat004",

    friend: Friend(

      id: "user004",

      name: "Martha",

      image: "assets/images/member1.png",

      isOnline: false,

    ),

    messages: [

      Message(

        id: "msg004",

        text: "Hey, Check this out",

        time: "12:00 PM",

        isMe: false,

      ),

    ],

  ),

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

                    "Messages",

                    style: TextStyle(

                      fontSize: 28,
                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  const Spacer(),
                  IconButton(

                    onPressed: () {

                      // Search action

                    },

                    icon: const Icon(
                      Icons.search,
                      size: 28,
                    ),

                  ),


                  IconButton(

                    onPressed: () {

                      // Video call action

                    },

                    icon: const Icon(
                      Icons.videocam_outlined,
                      size: 28,
                    ),

                  ),


                  IconButton(

                    onPressed: () {

                      // Phone call action

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
              // Messages List
              // =====================

              Expanded(

                child: ListView.builder(

                  itemCount: chats.length,

                  itemBuilder: (context, index) {


                    final chat = chats[index];


                    return InkWell(

                      onTap: () {

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (context) => ChatPage(chat: chat),

                          ),

                        );

                      },


                      child: Container(

                        margin: const EdgeInsets.only(
                          bottom: 15,
                        ),

                        child: Row(

                          children: [

                            // User Image
                            Stack(

                              children: [

                                CircleAvatar(

                                  radius: 30,

                                  backgroundImage: AssetImage(
                                    chat.friend.image,
                                  ),

                                ),
                                // Online Indicator
                                if (chat.friend.isOnline)

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


                            // Name and Message
                            Expanded(

                              child: Column(

                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [

                                  Text(

                                    chat.friend.name,

                                    style: const TextStyle(

                                      fontSize: 18,

                                      fontWeight: FontWeight.bold,

                                    ),

                                  ),


                                  const SizedBox(height: 5),


                                  Text(

                                    chat.messages.last.text,

                                    style: TextStyle(

                                      color: chat.messages.last.text ==
                                              "Typing..."
                                          ? const Color(0xFF008000)
                                          : Colors.grey,

                                      fontWeight:
                                          chat.messages.last.text ==
                                                  "Typing..."
                                              ? FontWeight.bold
                                              : FontWeight.normal,

                                    ),

                                  ),

                                ],

                              ),

                            ),


                            // Time
                            Text(

                              chat.messages.last.time,

                              style: const TextStyle(

                                color: Colors.grey,

                                fontSize: 12,

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