import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../Profile/profile_page.dart';
import '../services/buddyboss_service.dart';
import 'comments_sheet.dart';

class PostCard extends StatelessWidget {
  final Post post;
  /// Fires after any in-place mutation to [post] (like, pin, ...) so the
  /// parent can repaint. Renamed from the old `onLikeChanged` now that
  /// more than the like button uses it.
  final VoidCallback? onPostChanged;

  const PostCard({
  super.key,
  required this.post,
  this.onPostChanged,
});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (post.isPinned)
  const Padding(
    padding: EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Icon(
          Icons.push_pin,
          size: 14,
          color: Colors.orange,
        ),
        SizedBox(width: 4),
        Text(
          "Pinned",
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
                 GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          userId: post.userId,
        ),
      ),
    );
  },
  child: CircleAvatar(
    radius: 24,
    backgroundColor: Colors.grey.shade200,
    backgroundImage: post.profileImage.isNotEmpty
        ? CachedNetworkImageProvider(post.profileImage)
        : null,
    child: post.profileImage.isEmpty
        ? const Icon(Icons.person)
        : null,
  ),
),
                const SizedBox(width: 12),
              Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

       GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          userId: post.userId,
        ),
      ),
    );
  },
  child: Text(
    post.username,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  ),
),
      const SizedBox(height: 3),

      Row(
        children: [

          if (post.profession.isNotEmpty)

            Flexible(
              child: Text(
                post.profession,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(width: 6),

          Text(
            post.time.isEmpty
                ? post.createdAt.toString().substring(0,10)
                : post.time,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),

          const SizedBox(width: 5),

          Icon(
            post.privacy == "public"
                ? Icons.public
                : Icons.lock_outline,
            size: 14,
            color: Colors.grey,
          ),
        ],
      ),
    ],
  ),
),

PopupMenuButton<String>(
  icon: const Icon(Icons.more_horiz),
  onSelected: (value) async {
    switch (value) {
      case "edit":
        // TODO: Edit post
        break;

      case "delete":
        // TODO: Delete post
        break;

      case "pin":
      case "unpin":
        try {
          final updated =
              await BuddyBossService().togglePin(int.parse(post.id));
          post.isPinned = updated.isPinned;
          onPostChanged?.call();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Couldn't update pin: $e")),
            );
          }
        }
        break;

      case "report":
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("Report post"),
            content: const Text(
              "Are you sure you want to report this post?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Post reported"),
                    ),
                  );
                },
                child: const Text("Report"),
              ),
            ],
          ),
        );
        break;
    }
  },
  itemBuilder: (_) {
    if (post.canEdit) {
      return [
        const PopupMenuItem(
          value: "edit",
          child: Text("Edit"),
        ),
        const PopupMenuItem(
          value: "delete",
          child: Text("Delete"),
        ),
        // No confirmed permission field exists for pinning specifically
        // (only can_edit/can_delete/can_comment are), so this reuses the
        // same owner-level gate as edit/delete rather than a dedicated one.
        PopupMenuItem(
          value: post.isPinned ? "unpin" : "pin",
          child: Text(post.isPinned ? "Unpin" : "Pin to top"),
        ),
      ];
    }

    return const [
      PopupMenuItem(
        value: "report",
        child: Text("Report"),
      ),
    ];
  },
),
              ],
            ),

            const SizedBox(height: 15),

            Html(
  data: post.caption,
  style: {
    "body": Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      fontSize: FontSize(15),
      lineHeight: const LineHeight(1.5),
    ),
    "p": Style(
      margin: Margins.only(bottom: 10),
    ),
  },
),

            if (post.postImage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(15),
                  child:  CachedNetworkImage(
  imageUrl: post.postImage,
  width: double.infinity,
  fit: BoxFit.cover,

  placeholder: (_,__) => Container(
    height: 250,
    alignment: Alignment.center,
    child: const CircularProgressIndicator(),
  ),

  errorWidget: (_,__,___) =>
      const SizedBox.shrink(),
),
                ),
              ),

if (post.previewData.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Html(
      data: post.previewData,
    ),
  ),

            const SizedBox(height: 18),
            const Divider(height: 28),

          Row(
  children: [
    Expanded(
      child: TextButton.icon(
        onPressed: () async {
  final updated = await BuddyBossService().toggleFavorite(
    int.parse(post.id),
  );

  post.likes = updated.likes;
  post.isFavorited = updated.isFavorited;

  onPostChanged?.call();
},
        icon: Icon(
  post.isFavorited
      ? Icons.favorite
      : Icons.favorite_border,
  color: post.isFavorited ? Colors.red : null,
),
        label: Text(post.likes.toString()),
      ),
    ),
    Expanded(
      child: TextButton.icon(
        onPressed: () => CommentsSheet.show(context, post),
        icon: const Icon(Icons.chat_bubble_outline),
        label: Text(post.comments.toString()),
      ),
    ),
    Expanded(
      child: TextButton.icon(
        onPressed: () async {
  // Optimistic increment, no reliance on the response shape - see
  // BuddyBossService.shareActivity's doc comment for why.
  final previousShares = post.shares;
  post.shares += 1;
  onPostChanged?.call();

  try {
    await BuddyBossService().shareActivity(post.id);
  } catch (e) {
    post.shares = previousShares;
    onPostChanged?.call();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't share post: $e")),
      );
    }
  }
},
        icon: const Icon(Icons.share_outlined),
        label: Text(post.shares.toString()),
      ),
    ),
  ],
),
          ],
        ),
      ),
    );
  }
}
