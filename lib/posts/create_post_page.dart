import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/buddyboss_service.dart';
import '../services/auth_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {


  final TextEditingController postController =
    TextEditingController();

final ImagePicker picker = ImagePicker();
final BuddyBossService buddyBossService = BuddyBossService();

File? selectedImage;

bool isLoading = false;

bool schedulePost = false;

bool uploadHighQuality = true;

bool turnOffComments = false;

  @override
  void dispose() {
    postController.dispose();
    super.dispose();
  }
Future<void> pickImage() async {
  final image = await picker.pickImage(
    source: ImageSource.gallery,
  );

  if (image != null) {
    setState(() {
      selectedImage = File(image.path);
    });
  }
}

 Future<void> publishPost() async {
  if (postController.text.trim().isEmpty && selectedImage == null) {
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    await buddyBossService.createPost(
      content: postController.text.trim(),
      privacy: "public",
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

  @override
Widget build(BuildContext context) {

  return Scaffold(

    backgroundColor: Colors.white,

    body:  SafeArea(
  child: SingleChildScrollView(
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
                FutureBuilder(
  future: AuthService().getCurrentUser(),
  builder: (context, snapshot) {
    String avatar = "";

    if (snapshot.hasData) {
      final user = (snapshot.data as dynamic).data;

      avatar =
          user["avatar_urls"]?["thumb"] ??
          user["avatar_urls"]?["full"] ??
          "";
    }

    return CircleAvatar(
      radius: 18,
      backgroundImage: avatar.isNotEmpty
          ? NetworkImage(avatar)
          : const AssetImage("assets/images/member1.png")
              as ImageProvider,
    );
  },
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
            if (selectedImage != null)
  Padding(
    padding: const EdgeInsets.only(top: 15),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.file(
        selectedImage!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
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

      onPressed: pickImage,

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

  value: schedulePost,

onChanged: (value) {
  setState(() {
    schedulePost = value;
  });
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

value: uploadHighQuality,

onChanged: (value) {
  setState(() {
    uploadHighQuality = value;
  });
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

 value: turnOffComments,

onChanged: (value) {
  setState(() {
    turnOffComments = value;
  });
},
  title: const Text(
    "Turn off commenting",
  ),

  secondary: const Icon(
    Icons.comments_disabled_outlined,
  ),

),


// ======================
// Bottom Buttons
// ======================

Row(

  children: [

    Expanded(
  child: GestureDetector(
    onTap: () {
      // Save Draft later
    },
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
),


    const SizedBox(width: 20),


    // Publish Button
     Expanded(
  child: GestureDetector(
    onTap: isLoading ? null : publishPost,
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

         child: Center(
  child: isLoading
      ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
      : const Text(
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
),
  ],

),

const SizedBox(height: 15),

          ],

        ),

      ),

    ),
    ),
  );

}

}