import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/features/activity/models/post_model.dart';
import 'package:k54_mobile/features/profile/screens/profile_page.dart';
import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/features/activity/screens/create_post_page.dart';
import 'package:k54_mobile/features/activity/widgets/comments_sheet.dart';

class PostCard extends StatelessWidget {
  final Post post;
  /// Fires after any in-place mutation to [post] (like, pin, ...) so the
  /// parent can repaint. Renamed from the old `onLikeChanged` now that
  /// more than the like button uses it.
  final VoidCallback? onPostChanged;
  /// Fires when the post has been replaced wholesale (edit changes several
  /// final fields at once, so unlike like/pin it can't be mutated in place
  /// - the parent must swap this post for [updated] in its own list).
  final ValueChanged<Post>? onPostUpdated;
  /// Fires after the post has been deleted server-side - the parent should
  /// remove it from its own list.
  final VoidCallback? onPostDeleted;

  const PostCard({
  super.key,
  required this.post,
  this.onPostChanged,
  this.onPostUpdated,
  this.onPostDeleted,
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
                 TapScale(
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
  borderRadius: BorderRadius.circular(24),
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

       TapScale(
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
        final updated = await Navigator.push<Post>(
          context,
          MaterialPageRoute(
            builder: (_) => CreatePostPage(editingPost: post),
          ),
        );
        if (updated != null) {
          onPostUpdated?.call(updated);
        }
        break;

      case "delete":
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("Delete post"),
            content: const Text(
              "This can't be undone. Delete this post?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirmed != true) break;

        try {
          await BuddyBossService().deletePost(post.id);
          onPostDeleted?.call();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Couldn't delete post: $e")),
            );
          }
        }
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

      case "close_comments":
      case "open_comments":
        final closing = value == "close_comments";
        final previous = post.commentsClosed;
        post.commentsClosed = closing;
        onPostChanged?.call();
        try {
          await BuddyBossService().toggleCommentsClosed(post.id, closing);
        } catch (e) {
          post.commentsClosed = previous;
          onPostChanged?.call();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Couldn't update comments: $e")),
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
        PopupMenuItem(
          value: post.commentsClosed ? "open_comments" : "close_comments",
          child: Text(
            post.commentsClosed ? "Open Comments" : "Close Comments",
          ),
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

  placeholder: (_,_) => Container(
    height: 250,
    alignment: Alignment.center,
    child: const CircularProgressIndicator(),
  ),

  errorWidget: (_,_,_) =>
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
      child: _LikeButton(
        isFavorited: post.isFavorited,
        count: post.likes,
        onTap: () async {
  // Optimistic, same pattern as Share below - flips instantly instead
  // of waiting on the round-trip, then reconciles with the server's
  // real numbers (or reverts on failure).
  final wasFavorited = post.isFavorited;
  final previousLikes = post.likes;
  post.isFavorited = !wasFavorited;
  post.likes += wasFavorited ? -1 : 1;
  onPostChanged?.call();

  try {
    final updated = await BuddyBossService().toggleFavorite(
      int.parse(post.id),
    );
    post.likes = updated.likes;
    post.isFavorited = updated.isFavorited;
    onPostChanged?.call();
  } catch (e) {
    post.isFavorited = wasFavorited;
    post.likes = previousLikes;
    onPostChanged?.call();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't update like: $e")),
      );
    }
  }
},
      ),
    ),
    Expanded(
      child: TextButton.icon(
        onPressed: () => CommentsSheet.show(context, post, onPostChanged: onPostChanged),
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
    Expanded(
      child: TextButton.icon(
        onPressed: () {
          final plainText = post.caption.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          SharePlus.instance.share(
            ShareParams(text: "${post.username} on K54 Global:\n\n$plainText"),
          );
        },
        icon: const Icon(Icons.send_outlined),
        label: const Text("Send"),
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

/// A real "pop" on like, the single most recognizable micro-interaction
/// on any social feed (Instagram/Facebook/Twitter all do this) - the
/// plain TextButton.icon this replaced just swapped the icon instantly
/// with no motion at all, which reads as static no matter how correct
/// the layout is.
class _LikeButton extends StatefulWidget {
  final bool isFavorited;
  final int count;
  final VoidCallback onTap;

  const _LikeButton({required this.isFavorited, required this.count, required this.onTap});

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 60),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isFavorited) _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _handleTap,
      icon: ScaleTransition(
        scale: _scale,
        child: Icon(
          widget.isFavorited ? Icons.favorite : Icons.favorite_border,
          color: widget.isFavorited ? Colors.red : null,
        ),
      ),
      label: Text(widget.count.toString()),
    );
  }
}
