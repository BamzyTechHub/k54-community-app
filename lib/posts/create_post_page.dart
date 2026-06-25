import 'package:flutter/material.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {

  final TextEditingController postController =
      TextEditingController();

  @override
  void dispose() {
    postController.dispose();
    super.dispose();
  }

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

            // ======================
            // Header
            // ======================

            Row(

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

                const SizedBox(width: 8),


                // User image
                const CircleAvatar(

                  radius: 18,

                  backgroundImage: AssetImage(
                    "assets/images/member1.png",
                  ),

                ),


                const SizedBox(width: 10),


                // Privacy selector
                const Row(

                  children: [

                    Text(

                      "Anyone",

                      style: TextStyle(

                        fontSize: 16,

                        fontWeight: FontWeight.w600,

                      ),

                    ),


                    SizedBox(width: 5),


                    Icon(
                      Icons.keyboard_arrow_down,
                    ),

                  ],

                ),

              ],

            ),


            const SizedBox(height: 25),


            // ======================
            // Post Text Area
            // ======================

            Container(

              width: double.infinity,

              height: 250,

              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(

                border: Border.all(
                  color: Colors.grey.shade300,
                ),

                borderRadius: BorderRadius.circular(20),

              ),

              child: TextField(

                controller: postController,

                maxLines: null,

                decoration: const InputDecoration(

                  hintText: "Share your thoughts...",

                  border: InputBorder.none,

                ),

              ),

            ),
const SizedBox(height: 15),

// ======================
// AI + Media Actions
// ======================

Row(

  children: [

    // Create with AI Button
    Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      decoration: BoxDecoration(

        border: Border.all(
          color: Colors.purple.shade200,
        ),

        borderRadius: BorderRadius.circular(20),

      ),

      child: const Row(

        children: [

          Icon(
            Icons.auto_awesome,
            size: 16,
            color: Colors.purple,
          ),

          SizedBox(width: 5),

          Text(
            "Create post with AI",
            style: TextStyle(
              color: Colors.purple,
              fontSize: 12,
            ),
          ),

        ],

      ),

    ),

    const Spacer(),


    // Video
    IconButton(

      onPressed: () {

        // Upload video later

      },

      icon: const Icon(
        Icons.play_circle_outline,
      ),

    ),


    // Image
    IconButton(

      onPressed: () {

        // Pick image later

      },

      icon: const Icon(
        Icons.camera_alt_outlined,
      ),

    ),


    // Attachment
    IconButton(

      onPressed: () {

        // Attach file later

      },

      icon: const Icon(
        Icons.attach_file,
      ),

    ),


    // Emoji
    IconButton(

      onPressed: () {

        // Emoji picker later

      },

      icon: const Icon(
        Icons.sentiment_satisfied_alt_outlined,
      ),

    ),

  ],

),

const SizedBox(height: 30),
// ======================
// Post Settings
// ======================

SwitchListTile(

  contentPadding: EdgeInsets.zero,

  value: false,

  onChanged: (value) {

    // Schedule post later

  },

  title: const Text(
    "Schedule this post",
  ),

  secondary: const Icon(
    Icons.calendar_today_outlined,
  ),

),


SwitchListTile(

  contentPadding: EdgeInsets.zero,

  value: false,

  onChanged: (value) {

    // Upload quality later

  },

  title: const Text(
    "Upload at highest quality",
  ),

  secondary: const Icon(
    Icons.high_quality_outlined,
  ),

),


SwitchListTile(

  contentPadding: EdgeInsets.zero,

  value: false,

  onChanged: (value) {

    // Turn comments off later

  },

  title: const Text(
    "Turn off commenting",
  ),

  secondary: const Icon(
    Icons.comments_disabled_outlined,
  ),

),


const Spacer(),


// ======================
// Bottom Buttons
// ======================

Row(

  children: [

    // Save Draft Button
    Expanded(

      child: Container(

        height: 55,

        decoration: BoxDecoration(

          border: Border.all(
            color: const Color(0xFF008000),
            width: 2,
          ),

          borderRadius: BorderRadius.circular(30),

        ),

        child: const Center(

          child: Text(

            "Save Draft",

            style: TextStyle(

              color: Color(0xFF008000),

              fontSize: 16,

              fontWeight: FontWeight.bold,

            ),

          ),

        ),

      ),

    ),


    const SizedBox(width: 20),


    // Publish Button
    Expanded(

      child: Container(

        height: 55,

        decoration: BoxDecoration(

          borderRadius: BorderRadius.circular(30),

          gradient: const LinearGradient(

            colors: [

              Color(0xFF008000),

              Color(0xFFAB8000),

              Color(0xFF008000),

            ],

          ),

        ),

        child: const Center(

          child: Text(

            "Publish",

            style: TextStyle(

              color: Colors.white,

              fontSize: 16,

              fontWeight: FontWeight.bold,

            ),

          ),

        ),

      ),

    ),

  ],

),

const SizedBox(height: 15),

          ],

        ),

      ),

    ),

  );

}

}