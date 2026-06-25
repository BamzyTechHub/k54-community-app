import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatPage extends StatefulWidget {

  final Chat chat;


  const ChatPage({
    super.key,
    required this.chat,
  });


  @override
  State<ChatPage> createState() => _ChatPageState();

}


class _ChatPageState extends State<ChatPage> {


  // Message input controller
  final TextEditingController messageController =
      TextEditingController();



  @override
  void dispose() {

    messageController.dispose();

    super.dispose();

  }


  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor: Colors.white,


      body: SafeArea(

        child: Column(

          children: [

            // =========================
            // Chat Header
            // =========================

            Container(

              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),

              child: Row(

                children: [

                  // Back button
                  IconButton(

                    onPressed: () {

                      Navigator.pop(context);

                    },

                    icon: const Icon(
                      Icons.arrow_back,
                      size: 28,
                    ),

                  ),


                  // User Avatar
                  CircleAvatar(

  radius: 22,

  backgroundImage: AssetImage(
    widget.chat.friend.image,
  ),

),

                  const SizedBox(width: 10),


                  // User info
                  Column(

  crossAxisAlignment: CrossAxisAlignment.start,

  children: [

    Text(

      widget.chat.friend.name,

      style: const TextStyle(

        fontSize: 18,

        fontWeight: FontWeight.bold,

      ),

    ),


    Text(

      widget.chat.friend.isOnline
          ? "Online"
          : "Offline",

      style: TextStyle(

        color: widget.chat.friend.isOnline
            ? Colors.green
            : Colors.grey,

        fontSize: 13,

      ),

    ),

  ],

),
                  const Spacer(),
                  // Voice Call Button
                  IconButton(

                    onPressed: () {

                      // Voice call later

                    },

                    icon: const Icon(
                      Icons.call_outlined,
                      size: 26,
                    ),

                  ),


                  // Video Call Button
                  IconButton(

                    onPressed: () {

                      // Video call later

                    },

                    icon: const Icon(
                      Icons.videocam_outlined,
                      size: 26,
                    ),

                  ),

                ],

              ),

            ),


            const Divider(
              height: 1,
            ),


            // =========================
            // Chat Messages Area
            // =========================

            Expanded(

              child: ListView.builder(

                padding: const EdgeInsets.all(15),

                itemCount: widget.chat.messages.length,

                itemBuilder: (context, index) {


                  final message = widget.chat.messages[index];


                  return Align(

                    alignment: message.isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,


                    child: Container(

                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),

                      decoration: BoxDecoration(

                        color: message.isMe
                            ? const Color(0xFF008000)
                            : const Color(0xFFF3EFD9),


                        borderRadius: BorderRadius.only(

                          topLeft: const Radius.circular(18),

                          topRight: const Radius.circular(18),

                          bottomLeft: Radius.circular(
                            message.isMe ? 18 : 0,
                          ),

                          bottomRight: Radius.circular(
                            message.isMe ? 0 : 18,
                          ),

                        ),

                      ),


                      child: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.end,

                        children: [

                          Text(

                            message.text,

                            style: TextStyle(

                              color: message.isMe
                                  ? Colors.white
                                  : Colors.black,

                              fontSize: 15,

                            ),

                          ),


                          const SizedBox(height: 5),


                          Text(

                            message.time,

                            style: TextStyle(

                              color: message.isMe
                                  ? Colors.white70
                                  : Colors.grey,

                              fontSize: 11,

                            ),

                          ),

                        ],

                      ),

                    ),

                  );

                },

              ),

            ),
            // =========================
            // Message Input Area
            // =========================

            Container(

              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),

              decoration: BoxDecoration(

                color: Colors.white,

                border: Border(

                  top: BorderSide(
                    color: Colors.grey.shade300,
                  ),

                ),

              ),

              child: Row(

                children: [

                  // Emoji Button
                  IconButton(

                    onPressed: () {

                      // Emoji picker later

                    },

                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey,
                    ),

                  ),


                  // Attachment Button
                  IconButton(

                    onPressed: () {

                      // File attachment later

                    },

                    icon: const Icon(
                      Icons.attach_file,
                      color: Colors.grey,
                    ),

                  ),


                  // Message Text Field
                  Expanded(

                    child: Container(

                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                      ),

                      decoration: BoxDecoration(

                        color: const Color(0xFFF3EFD9),

                        borderRadius: BorderRadius.circular(25),

                      ),

                      child: TextField(

                        controller: messageController,

                        decoration: const InputDecoration(

                          hintText: "Type a message...",

                          border: InputBorder.none,

                        ),

                      ),

                    ),

                  ),


                  const SizedBox(width: 5),


                  // Voice Message Button
                  IconButton(

                    onPressed: () {

                      // Voice recording later

                    },

                    icon: const Icon(

                      Icons.mic_none,

                      color: Colors.grey,

                    ),

                  ),


                  // Send Button
                  IconButton(

                    onPressed: () {

                      if (messageController.text
                          .trim()
                          .isNotEmpty) {

                        setState(() {

                          widget.chat.messages.add(

                            Message(

                              id: "msg${widget.chat.messages.length + 1}",

                              text: messageController.text.trim(),

                              time: "Now",

                              isMe: true,

                            )

                          );

                        });

                        messageController.clear();

                      }

                    },

                    icon: const Icon(

                      Icons.send,

                      color: Color(0xFF008000),

                    ),

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }

}