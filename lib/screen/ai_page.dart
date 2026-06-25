import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {

  // AI Message Controller
  final TextEditingController messageController =
      TextEditingController();


  // Quick AI Suggestions
  final List<String> quickSearches = [
    "Grow My Business",
    "Scale My Results",
    "Create NGO Community",
    "Start Study Group",
    "Create Church Group",
    "Create My First Course",
  ];


  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,


      // K54 Bottom Navigation
      bottomNavigationBar: const K54BottomNavigation(
        currentIndex: 1,
      ),


      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),


          child: SingleChildScrollView(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // K54 AI Header

                const Text(
                  "K54 AI Assistant",

                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),


                const SizedBox(height: 8),


                const Text(
                  "Your intelligent assistant for learning, communities and growth.",

                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),


                const SizedBox(height: 25),


                // AI Chat Container

                Container(

                  width: double.infinity,
                  height: 220,

                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(

                    color: const Color(0xFFF9F9F9),

                    border: Border.all(
                      color: const Color(0xFFDADADA),
                    ),

                    borderRadius:
                        BorderRadius.circular(20),

                  ),

                  child: Column(

                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "🤖 K54 AI",

                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                          color: Color(0xFF008000),
                        ),
                      ),

                      const SizedBox(height: 12),


                      const Text(
                        "Hello 👋\nHow can I help you today?",

                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),

                      const Spacer(),

                      const Text(
                        "AI responses will appear here.",

                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),

                    ],

                  ),

                ),


                const SizedBox(height: 20),


                // Part 2 continues here
                // Ask K54 AI Input

Container(

  padding: const EdgeInsets.symmetric(
    horizontal: 15,
  ),

  decoration: BoxDecoration(

    border: Border.all(
      color: const Color(0xFF008000),
      width: 1.5,
    ),

    borderRadius: BorderRadius.circular(30),

  ),

  child: Row(

    children: [

      Expanded(

        child: TextField(

          controller: messageController,

          decoration: const InputDecoration(

            hintText: "Ask K54 AI anything...",

            hintStyle: TextStyle(
              color: Colors.grey,
            ),

            border: InputBorder.none,

          ),

        ),

      ),


      IconButton(

        onPressed: () {

          if (messageController.text.trim().isNotEmpty) {

            // Future AI API call goes here
            print(
              "User asked: ${messageController.text}",
            );

            messageController.clear();

          }

        },

        icon: const Icon(
          Icons.send_rounded,
          color: Color(0xFF008000),
          size: 26,
        ),

      ),

    ],

  ),

),


const SizedBox(height: 25),


// Quick Actions Header

const Text(

  "Quick Actions",

  style: TextStyle(

    fontSize: 18,

    fontWeight: FontWeight.bold,

  ),

),


const SizedBox(height: 15),


// K54 Action Buttons

Wrap(

  spacing: 12,

  runSpacing: 15,

  children: [

    _actionButton(
      "Create First Course",
    ),

    _actionButton(
      "Create NGO Community",
    ),

    _actionButton(
      "Create Church Group",
    ),

    _actionButton(
      "Start Study Group",
    ),

  ],

),


const SizedBox(height: 25),


// Quick Search Header

const Text(

  "Popular Searches",

  style: TextStyle(

    fontSize: 18,

    fontWeight: FontWeight.bold,

  ),

),


const SizedBox(height: 15),


// Search Suggestions

Wrap(

  spacing: 10,

  runSpacing: 12,

  children: quickSearches.map((item) {

    return GestureDetector(

      onTap: () {

        setState(() {

          messageController.text = item;

        });

      },

      child: Container(

        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),

        decoration: BoxDecoration(

          borderRadius:
              BorderRadius.circular(25),

          gradient: const LinearGradient(

            colors: [

              Color(0xFF008000),

              Color(0xFFAB8000),

              Color(0xFF008000),

            ],

          ),

        ),

        child: Text(

          item,

          style: const TextStyle(

            color: Colors.white,

            fontWeight: FontWeight.w600,

            fontSize: 13,

          ),

        ),

      ),

    );

  }).toList(),

),


const SizedBox(height: 30),


// Part 3 continues here
],

            ),

          ),

        ),

      ),

    );

  }


  // K54 Quick Action Button

  Widget _actionButton(String text) {

    return GestureDetector(

      onTap: () {

        setState(() {

          messageController.text = text;

        });

      },


      child: Container(

        width: 165,

        height: 55,

        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),

        decoration: BoxDecoration(

          borderRadius: BorderRadius.circular(28),

          gradient: const LinearGradient(

            colors: [

              Color(0xFF008000),

              Color(0xFFAB8000),

              Color(0xFF008000),

            ],

          ),

        ),


        child: Center(

          child: Text(

            text,

            textAlign: TextAlign.center,

            style: const TextStyle(

              color: Colors.white,

              fontSize: 13,

              fontWeight: FontWeight.w600,

            ),

          ),

        ),

      ),

    );

  }

}