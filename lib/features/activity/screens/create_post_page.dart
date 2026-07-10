import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:k54_mobile/features/activity/models/post_model.dart';
import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/features/ai/screens/ai_page.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';

class CreatePostPage extends StatefulWidget {
  /// When set, this screen edits [editingPost] instead of composing a new
  /// one - reuses the same composer UI rather than a separate edit screen,
  /// since no distinct edit design exists and the two flows are otherwise
  /// identical (text + privacy, currently).
  final Post? editingPost;

  const CreatePostPage({super.key, this.editingPost});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {

  bool get _isEditing => widget.editingPost != null;

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
  void initState() {
    super.initState();
    final editing = widget.editingPost;
    if (editing != null) {
      postController.text = editing.caption;
    }
  }

  @override
  void dispose() {
    postController.dispose();
    super.dispose();
  }
void _comingSoon(String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("$feature is coming soon")),
  );
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

  // Image upload isn't wired to the API yet (BuddyBoss's featured-image
  // endpoint exists but its exact request shape hasn't been confirmed
  // against a live response, so guessing at it here would risk a "fix"
  // that silently fails). Until then, ask instead of dropping the image
  // without telling the user — the previous behavior published text-only
  // with no indication the photo never made it.
  if (selectedImage != null) {
    final proceedWithoutImage = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Photo not supported yet"),
        content: const Text(
          "Attaching a photo isn't available yet. Publishing now will "
          "post your text only, without the image. Continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Publish Without Photo"),
          ),
        ],
      ),
    );
    if (proceedWithoutImage != true) return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    final editing = widget.editingPost;
    if (editing != null) {
      final updated = await buddyBossService.updatePost(
        activityId: editing.id,
        content: postController.text.trim(),
        privacy: editing.privacy,
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } else {
      final created = await buddyBossService.createPost(
        content: postController.text.trim(),
        privacy: "public",
      );
      if (turnOffComments) {
        try {
          await buddyBossService.toggleCommentsClosed(created.id, true);
        } catch (_) {
          // The post itself published fine - a failed follow-up toggle
          // isn't worth blocking on or rolling back for.
        }
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  } catch (e) {
    if (!mounted) return;
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


                // Privacy selector - always publishes as "public" (see
                // publishPost) since no confirmed way exists yet to send
                // any other privacy value, so this is honestly a
                // coming-soon tap rather than a dropdown with no effect.
                GestureDetector(
                  onTap: () => _comingSoon("Choosing who can see this post"),
                  child: const Row(

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

    // Create with AI Button - routes to the real, working AI Assistant
    // rather than doing nothing, since that's genuine functionality this
    // app already has.
    GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiPage()),
      ),
      child: Container(

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
    ),


    // Video
    IconButton(

      onPressed: () => _comingSoon("Attaching a video"),

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

      onPressed: () => _comingSoon("Attaching a file"),

      icon: const Icon(
        Icons.attach_file,
      ),

    ),


    // Emoji
    IconButton(

      onPressed: () => _comingSoon("Emoji picker"),

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
    onTap: () => _comingSoon("Saving drafts"),
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
  child: PrimaryButton(
    label: _isEditing ? "Save Changes" : "Publish",
    loading: isLoading,
    onPressed: publishPost,
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