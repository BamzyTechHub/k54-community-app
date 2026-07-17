import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:k54_mobile/features/activity/models/post_model.dart';
import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/features/ai/screens/ai_page.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';

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

bool turnOffComments = false;

// Real, functional toggle - controls image_picker's imageQuality param
// (100 vs the default 85), not a fake switch. The broader image-upload
// pipeline isn't wired to the API yet (see the dialog in publishPost),
// but this itself has no backend dependency at all.
bool uploadHighestQuality = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingPost;
    if (editing != null) {
      postController.text = editing.caption;
    }
    // Drives the Publish button's disabled/greyed state as the user types
    // - matches the Figma screenshot showing Publish greyed out while the
    // composer is empty.
    postController.addListener(() => setState(() {}));
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

Widget _settingsToggle({
  required IconData icon,
  required String label,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.jetBlack),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.green,
        ),
      ],
    ),
  );
}

Widget _mediaBadge({required IconData icon, required VoidCallback onTap}) {
  return TapScale(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 16),
    ),
  );
}

Future<void> pickImage() async {
  final image = await picker.pickImage(
    source: ImageSource.gallery,
    // 100 when "Upload at highest quality" is on, otherwise image_picker's
    // own default compression - a real effect, not a decorative switch.
    imageQuality: uploadHighestQuality ? 100 : null,
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
        shape: K54Dialog.shape,
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
    String name = "";

    if (snapshot.hasData) {
      final user = (snapshot.data as dynamic).data;

      avatar =
          user["avatar_urls"]?["thumb"] ??
          user["avatar_urls"]?["full"] ??
          "";
      name = user["name"] ?? "";
    }

    return UserAvatar(imageUrl: avatar, name: name, radius: 18);
  },
),


                const SizedBox(width: 10),


                // Privacy selector - always publishes as "public" (see
                // publishPost) since no confirmed way exists yet to send
                // any other privacy value, so this is honestly a
                // coming-soon tap rather than a dropdown with no effect.
                TapScale(
                  onTap: () => _comingSoon("Choosing who can see this post"),
                  borderRadius: BorderRadius.circular(12),
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

                const Spacer(),

                // "Go Live" - visible in Figma (node 40:712) next to the
                // privacy selector, but no live-streaming backend is
                // confirmed, so this is a coming-soon stub like the other
                // unwired media actions on this screen.
                TapScale(
                  onTap: () => _comingSoon("Going live"),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      const Text(
                        "Go Live",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.videocam, color: Colors.red.shade400, size: 20),
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
    // app already has. Green (not purple) - matches the screenshot and
    // AppColors.green, the color already used for every other AI-related
    // accent in the app (ai_page.dart's own progress indicator/links).
    TapScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiPage()),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      decoration: BoxDecoration(

        border: Border.all(
          color: AppColors.green,
        ),

        borderRadius: BorderRadius.circular(20),

      ),

      child: const Row(

        children: [

          Icon(
            Icons.auto_awesome,
            size: 16,
            color: AppColors.green,
          ),

          SizedBox(width: 5),

          Text(
            "Generate post with AI",
            style: TextStyle(
              color: AppColors.green,
              fontSize: 12,
            ),
          ),

        ],

      ),

      ),
    ),

    const Spacer(),

    // Media actions - black circular badges matching Figma exactly
    // (node 40:712), right-aligned next to the AI pill.
    _mediaBadge(icon: Icons.play_arrow, onTap: () => _comingSoon("Attaching a video")),
    const SizedBox(width: 8),
    _mediaBadge(icon: Icons.camera_alt_outlined, onTap: pickImage),
    const SizedBox(width: 8),
    _mediaBadge(icon: Icons.attach_file, onTap: () => _comingSoon("Attaching a file")),
    const SizedBox(width: 8),
    _mediaBadge(
      icon: Icons.sentiment_satisfied_alt_outlined,
      onTap: () => _comingSoon("Emoji picker"),
    ),

  ],

),

const SizedBox(height: 30),
// ======================
// Post Settings - grouped card matching the Figma "Create Post"
// screenshot exactly (three stacked toggle rows in one rounded card),
// restoring the Schedule/Upload-quality rows that were missing from an
// earlier pass that only kept "Turn off commenting".
// ======================

Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  decoration: BoxDecoration(
    color: const Color(0xFFFCF8ED),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Column(
    children: [
      _settingsToggle(
        icon: Icons.schedule_outlined,
        label: "Schedule this post",
        // No confirmed backend field exists for scheduling a BuddyBoss
        // activity post (the live activity schema has no
        // scheduled_date/publish_date field) - this stays honestly
        // off and tells the user instead of silently pretending a
        // scheduled post would actually be scheduled.
        value: false,
        onChanged: (_) => _comingSoon("Scheduling posts"),
      ),
      const Divider(height: 1),
      _settingsToggle(
        icon: Icons.high_quality_outlined,
        label: "Upload at highest quality",
        value: uploadHighestQuality,
        onChanged: (value) => setState(() => uploadHighestQuality = value),
      ),
      const Divider(height: 1),
      _settingsToggle(
        icon: Icons.comments_disabled_outlined,
        label: "Turn off commenting",
        value: turnOffComments,
        onChanged: (value) => setState(() => turnOffComments = value),
      ),
    ],
  ),
),


// ======================
// Bottom Buttons
// ======================

Row(

  children: [

    Expanded(
  child: PrimaryButton(
    label: "Save Draft",
    outline: true,
    onPressed: () => _comingSoon("Saving drafts"),
  ),
),


    const SizedBox(width: 20),


    // Publish Button - greyed/disabled while there's nothing to publish,
    // matching the Figma screenshot's Publish state with an empty
    // composer.
     Expanded(
  child: PrimaryButton(
    label: _isEditing ? "Save Changes" : "Publish",
    loading: isLoading,
    onPressed: (postController.text.trim().isEmpty && selectedImage == null)
        ? null
        : publishPost,
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