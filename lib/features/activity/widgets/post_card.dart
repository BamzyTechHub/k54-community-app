import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/open_profile.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';
import 'package:k54_mobile/features/activity/models/post_model.dart';
import 'package:k54_mobile/features/activity/models/reaction_type.dart';
import 'package:k54_mobile/features/activity/widgets/reaction_picker.dart';
import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/features/activity/screens/create_post_page.dart';
import 'package:k54_mobile/features/activity/widgets/comments_sheet.dart';
import 'package:k54_mobile/features/groups/repositories/groups_repository.dart';
import 'package:k54_mobile/features/groups/screens/group_detail_page.dart';
import 'package:k54_mobile/features/live_video/models/live_channel_status.dart';
import 'package:k54_mobile/features/live_video/repositories/live_video_repository.dart';
import 'package:k54_mobile/features/live_video/screens/live_watch_page.dart';

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
    // Long-press-to-select/copy wasn't enabled anywhere on the card - the
    // caption, username, and other text just weren't selectable at all.
    // SelectionArea is the standard Flutter mechanism for this and
    // doesn't interfere with the card's existing taps (avatar/username/
    // like/comment/etc. all keep working exactly as before).
    return SelectionArea(
      child: Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        // Exact values from the K54 HOME PAGE Figma frame (node 571:714),
        // pulled via the REST API 2026-07-16 - was AppColors.border/15
        // (an approximation) before this measurement existed.
        border: Border.all(color: const Color(0xFFFCF8ED)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
          color: AppColors.warning,
        ),
        SizedBox(width: 4),
        Text(
          "Pinned",
          style: TextStyle(
            color: AppColors.warning,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
                 TapScale(
  onTap: () => openProfile(context, post.userId),
  borderRadius: BorderRadius.circular(24),
  child: UserAvatar(
    imageUrl: null,
    imageProvider: post.profileImage.isNotEmpty
        ? CachedNetworkImageProvider(post.profileImage)
        : null,
    name: post.username,
    radius: 24,
    // stroke=#FCF8ED strokeWeight=2.0 on "Ellipse 214" - confirmed
    // directly against the raw node 571:714 JSON, not assumed.
    borderColor: const Color(0xFFFCF8ED),
    borderWidth: 2,
  ),
),
                // 8px gap between avatar and name column - exact match
                // from node 571:714 ("Frame 38196" autolayout gap=8),
                // was 12px before this measurement existed.
                const SizedBox(width: 8),
              Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

       TapScale(
  onTap: () => openProfile(context, post.userId),
  child: Text(
    post.username,
    // Poppins 16/700 #1A1A1A - exact match from the K54 HOME PAGE Figma
    // frame (node 571:714), pulled via the REST API 2026-07-16. Was the
    // system default font/weight with no explicit color before this
    // measurement existed.
    style: GoogleFonts.poppins(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: AppColors.jetBlack,
    ),
  ),
),
      // 4px gap (Frame 37570 autolayout gap=4.0) - was 3px.
      const SizedBox(height: 4),

      Row(
        children: [

          // post.profession is never populated (no such field exists on
          // the activity endpoint - see BuddyBossService.getUserProfession's
          // doc comment) - this fetches the author's real xprofile
          // profession instead, cached per author so a busy feed doesn't
          // re-fetch it for every post by the same person.
          _AuthorProfession(userId: post.userId),

          const SizedBox(width: 6),

          Icon(
            post.privacy == "public"
                ? Icons.public
                : Icons.lock_outline,
            size: 14,
            color: AppColors.grey,
          ),
        ],
      ),
    ],
  ),
),

_PostMenuButton(
  post: post,
  onPostChanged: onPostChanged,
  onPostUpdated: onPostUpdated,
  onPostDeleted: onPostDeleted,
),
              ],
            ),

            // 4px gap - matches node 571:714's card autolayout (gap=4
            // between header/body/image/actions), was 15px before this
            // measurement existed. This tight spacing (plus removing the
            // divider before the action row, below) is likely a big part
            // of what made the feed read as disconnected floating cards
            // rather than a cohesive scroll.
            const SizedBox(height: 4),

            if (post.isLiveStreamActivity)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LiveStreamCard(post: post),
              ),

            if (!post.isLiveStreamActivity)
            Html(
  data: post.caption,
  // Was completely unwired - a link in a post's text did nothing at
  // all when tapped. Opens externally rather than an in-app WebView,
  // matching how every other outbound link in this app already
  // behaves (Members/Groups profile links, Help Center's Terms/
  // Privacy links).
  onLinkTap: (url, attributes, element) {
    if (url != null) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  },
  style: {
    // Poppins 14/400 #1A1A1A - re-verified directly against the raw
    // node 571:714 JSON on 2026-07-16 (not from memory): the body text
    // node explicitly reads font=Poppins, not Lato. An earlier pass
    // wrongly wrote Lato here, conflated from a different frame's
    // (Messages/Friends/Groups) similarly-shaped but differently-styled
    // text node - exactly the kind of unverified-assumption mistake to
    // not repeat.
    "body": Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      fontSize: FontSize(14),
      fontFamily: GoogleFonts.poppins().fontFamily,
      color: AppColors.jetBlack,
      lineHeight: const LineHeight(1.5),
    ),
    "p": Style(
      margin: Margins.only(bottom: 10),
    ),
    // No underline - green alone reads as interactive, matching the
    // "joined group"/"connected with" activity mentions - direct tester
    // feedback that the underline looked off.
    "a": Style(
      color: AppColors.green,
      textDecoration: TextDecoration.none,
    ),
  },
),

            // Real deep link into the actual discussion thread - matches
            // the real site's own "Join Discussion" link on these two
            // activity types exactly (confirmed live 2026-07-22).
            if (post.discussionId != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _JoinDiscussionLink(activityType: post.activityType, discussionId: post.discussionId!),
              ),

            if (post.postImage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12),
                  child:  CachedNetworkImage(
  imageUrl: post.postImage,
  width: double.infinity,
  fit: BoxFit.cover,

  placeholder: (_,_) => Container(
    height: 250,
    alignment: Alignment.center,
    child: const CircularProgressIndicator(color: AppColors.green),
  ),

  errorWidget: (_,_,_) =>
      const SizedBox.shrink(),
),
                ),
              ),

if (post.photos.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: PostPhotosGrid(photos: post.photos),
  ),

if (post.videos.isNotEmpty)
  ...post.videos.map((video) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: PostVideoPlayer(video: video),
      )),

if (post.documents.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      children: post.documents
          .map((doc) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: PostDocumentTile(document: doc),
              ))
          .toList(),
    ),
  ),

if (post.previewData.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Html(
      data: post.previewData,
      onLinkTap: (url, attributes, element) {
        if (url != null) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
    ),
  ),

            const SizedBox(height: 4),

          Row(
  // Centered as a group (was left-packed - direct tester feedback that
  // the buttons "are not aligned to the center of the card"). Keeps the
  // fixed 64px gap between items from the K54 HOME PAGE frame (node
  // 571:714, "Frame 15357"), just no longer pinned to the left edge.
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    _LikeButton(
      reactedId: post.reactedId,
      count: post.likes,
      // Real BuddyBoss reactions system (confirmed live 2026-07-17 via
      // /buddyboss/v1/reactions and /buddyboss/v1/user-reactions), not
      // the older plain favorite/unfavorite boolean this replaced. A
      // plain tap toggles between "no reaction" and reactionId 635
      // (Like) - if the post already has a different reaction, a plain
      // tap on the same reactionId (see _LikeButton._handleTap) removes
      // it, matching "tap again to remove" rather than adding a second
      // like. Long-press opens the real reaction picker.
      onReact: (reactionId) async {
        final previousReactedId = post.reactedId;
        final previousLikes = post.likes;
        final isRemoving = reactionId == previousReactedId;
        final wasReacted = previousReactedId != 0;

        post.reactedId = isRemoving ? 0 : reactionId;
        if (!wasReacted && !isRemoving) post.likes += 1;
        if (wasReacted && isRemoving) post.likes -= 1;
        onPostChanged?.call();

        try {
          if (isRemoving) {
            await BuddyBossService().removeReaction(itemId: post.id);
          } else {
            await BuddyBossService().setReaction(
              itemId: post.id,
              reactionId: reactionId,
            );
          }
        } catch (e) {
          post.reactedId = previousReactedId;
          post.likes = previousLikes;
          onPostChanged?.call();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Couldn't update reaction: $e")),
            );
          }
        }
      },
    ),
    const SizedBox(width: 64),
    _ActionButton(
      icon: Icons.chat_bubble_outline,
      label: post.comments > 0 ? "${post.comments} Comments" : "Comment",
      onTap: () => CommentsSheet.show(context, post, onPostChanged: onPostChanged),
    ),
    const SizedBox(width: 64),
    _ActionButton(
      // Figma's node 571:714 action row names this icon
      // "hugeicons:repost" - repeat is the closest built-in match.
      icon: Icons.repeat,
      label: post.shares > 0 ? "${post.shares} Reposts" : "Repost",
      onTap: () async {
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
    ),
    const SizedBox(width: 64),
    _ActionButton(
      icon: Icons.send_outlined,
      label: "Send",
      onTap: () {
        final plainText = post.caption.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        SharePlus.instance.share(
          ShareParams(text: "${post.username} on K54 Global:\n\n$plainText"),
        );
      },
    ),
  ],
),
          ],
        ),
      ),
      ),
    );
  }
}

/// The post card's "..." menu - was a plain PopupMenuButton, which renders
/// in Flutter's stock Material purple since this app never sets a brand
/// ColorScheme/theme (flagged directly by the user - "not that purple").
/// Rebuilt with the same custom-overlay pattern already used for the
/// profile menu, filter popovers, and reaction picker: a plain white/
/// cream rounded card with the app's own colors, not a themed default
/// widget. Same menu items as before (Edit/Delete/Pin/Close-Comments for
/// the post's owner, Report for everyone else) - only the visual
/// treatment changed here, not the content (that's a separate,
/// deliberately deferred task pending a screenshot of the live site's
/// own menu).
class _PostMenuButton extends StatefulWidget {
  final Post post;
  final VoidCallback? onPostChanged;
  final ValueChanged<Post>? onPostUpdated;
  final VoidCallback? onPostDeleted;

  const _PostMenuButton({
    required this.post,
    this.onPostChanged,
    this.onPostUpdated,
    this.onPostDeleted,
  });

  @override
  State<_PostMenuButton> createState() => _PostMenuButtonState();
}

class _PostMenuButtonState extends State<_PostMenuButton> {
  final LayerLink _layerLink = LayerLink();

  void _openMenu() {
    final post = widget.post;
    // Built per-permission, not gated behind a single canEdit check - real
    // data confirmed live 2026-07-23 that a post commonly has can_edit:
    // false (WordPress's edit window has passed) while can_delete stays
    // true, which used to collapse the ENTIRE menu down to just "Report"
    // even though Delete/Pin/Close Comments should still be available
    // (direct tester feedback: "the only option there... is Report").
    final items = <({String value, String label, bool destructive})>[
      if (post.canEdit) (value: "edit", label: "Edit", destructive: false),
      if (post.canDelete) (value: "delete", label: "Delete", destructive: true),
      // No confirmed permission field exists for pinning/closing comments
      // specifically (only can_edit/can_delete/can_comment are) - reuses
      // can_delete as the "you own this post" gate since it stays true
      // longer than can_edit and is the closer match for "can manage this
      // post" than the time-limited edit window.
      if (post.canDelete)
        (value: post.isPinned ? "unpin" : "pin", label: post.isPinned ? "Unpin" : "Pin to top", destructive: false),
      if (post.canDelete)
        (
          value: post.commentsClosed ? "open_comments" : "close_comments",
          label: post.commentsClosed ? "Open Comments" : "Close Comments",
          destructive: false,
        ),
      if (!post.canEdit && !post.canDelete) (value: "report", label: "Report", destructive: false),
    ];

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => entry.remove(),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 4),
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 6,
              shadowColor: AppColors.black.withValues(alpha: 0.2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items
                      .map((item) => TapScale(
                            onTap: () {
                              entry.remove();
                              _handleAction(item.value);
                            },
                            child: Container(
                              width: 190,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Text(
                                item.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: item.destructive ? AppColors.error : AppColors.jetBlack,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }

  Future<void> _handleAction(String value) async {
    final post = widget.post;
    switch (value) {
      case "edit":
        final updated = await Navigator.push<Post>(
          context,
          MaterialPageRoute(builder: (_) => CreatePostPage(editingPost: post)),
        );
        if (updated != null) {
          widget.onPostUpdated?.call(updated);
        }
        break;

      case "delete":
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: K54Dialog.shape,
            title: const Text("Delete post"),
            content: const Text("This can't be undone. Delete this post?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("Delete", style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        if (confirmed != true) break;

        try {
          await BuddyBossService().deletePost(post.id);
          widget.onPostDeleted?.call();
        } catch (e) {
          // A thrown error here doesn't always mean the delete actually
          // failed server-side - confirmed live 2026-07-23 that a delete
          // call can succeed on the server (post genuinely gone) while the
          // client still sees an error for an unrelated reason, which
          // used to leave the "deleted" post stuck showing in the app
          // even though it no longer existed on the site. Checking the
          // real current state instead of guessing from the error alone.
          bool stillExists = true;
          try {
            await BuddyBossService().getActivity(post.id);
          } catch (_) {
            stillExists = false;
          }
          if (!stillExists) {
            widget.onPostDeleted?.call();
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Couldn't delete post: $e")),
            );
          }
        }
        break;

      case "pin":
      case "unpin":
        try {
          final updated = await BuddyBossService().togglePin(int.parse(post.id));
          post.isPinned = updated.isPinned;
          widget.onPostChanged?.call();
        } catch (e) {
          if (mounted) {
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
        widget.onPostChanged?.call();
        try {
          await BuddyBossService().toggleCommentsClosed(post.id, closing);
        } catch (e) {
          post.commentsClosed = previous;
          widget.onPostChanged?.call();
          if (mounted) {
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
            shape: K54Dialog.shape,
            title: const Text("Report post"),
            content: const Text("Are you sure you want to report this post?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Post reported")),
                  );
                },
                child: const Text("Report"),
              ),
            ],
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TapScale(
        onTap: _openMenu,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.more_horiz, color: AppColors.jetBlack),
        ),
      ),
    );
  }
}

/// A real "pop" on react, the single most recognizable micro-interaction
/// on any social feed (Instagram/Facebook/Twitter all do this) - the
/// plain TextButton.icon this replaced just swapped the icon instantly
/// with no motion at all, which reads as static no matter how correct
/// the layout is.
///
/// A plain tap toggles the default Like reaction on/off. A long-press
/// opens [showReactionPicker] with the real six-option BuddyBoss reaction
/// bar (Like/Love/Laugh/Angry/Sad/Wow), confirmed live against
/// `/buddyboss/v1/reactions` 2026-07-17 - not an invented emoji list.
class _LikeButton extends StatefulWidget {
  final int reactedId;
  final int count;
  final ValueChanged<int> onReact;

  const _LikeButton({required this.reactedId, required this.count, required this.onReact});

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  List<ReactionType> _reactionTypes = [];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 60),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    // Opportunistic prefetch so the picker opens instantly on a long-press
    // and so the button can render the exact reaction glyph (not just a
    // generic filled thumb) as soon as it's available. Silently falls
    // back to the generic thumb if this fails - the tap-to-toggle path
    // doesn't depend on it.
    BuddyBossService().getReactionTypes().then((types) {
      if (mounted) setState(() => _reactionTypes = types);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.reactedId == 0) _controller.forward(from: 0);
    // Tapping while already reacted re-sends the *same* reaction id, which
    // PostCard's onReact treats as "remove" - matches "tap again to
    // remove" rather than resetting to a plain Like.
    widget.onReact(widget.reactedId == 0 ? kLikeReactionId : widget.reactedId);
  }

  Future<void> _handleLongPress() async {
    var types = _reactionTypes;
    if (types.isEmpty) {
      try {
        types = await BuddyBossService().getReactionTypes();
        if (mounted) setState(() => _reactionTypes = types);
      } catch (_) {
        return;
      }
    }
    if (types.isEmpty || !mounted) return;

    showReactionPicker(
      context: context,
      layerLink: _layerLink,
      reactions: types,
      onSelected: (r) {
        if (widget.reactedId == 0) _controller.forward(from: 0);
        widget.onReact(r.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ReactionType? current;
    if (widget.reactedId != 0) {
      for (final t in _reactionTypes) {
        if (t.id == widget.reactedId) {
          current = t;
          break;
        }
      }
    }

    // TapScale (not a plain TextButton) - same press-down-slightly feedback
    // already used on the post avatar/username above, so every tappable
    // element on the card responds to touch consistently instead of the
    // action row being the one static-feeling part of it.
    return CompositedTransformTarget(
      link: _layerLink,
      child: TapScale(
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: current != null
                  ? ReactionGlyph(type: current, size: 18)
                  : Icon(
                      // Figma's node 571:714 action row uses a thumbs-up
                      // glyph for Like, not a heart - kept as the fallback
                      // for any non-Like reaction id before the real
                      // reaction list has loaded.
                      widget.reactedId != 0 ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 18,
                      color: widget.reactedId != 0 ? AppColors.green : AppColors.jetBlack,
                    ),
            ),
            // ~1px gap between icon and label, computed from the actual
            // node coordinates (icon bottom y=377, label top y=378) - not
            // an autolayout gap value, since this group has none declared.
            const SizedBox(height: 1),
            // Real count + word label together (was count-only, reverted
            // 2026-07-17 from Figma's static "Like" word since it had no
            // real data behind it - now restoring the word too per direct
            // tester feedback: "you have naming on only the send button...
            // try naming them all", combined with the real count rather
            // than dropping it). _AnimatedCount makes the value change
            // itself visible instead of an instant jump.
            _AnimatedCount(value: widget.count > 0 ? "${widget.count} Likes" : "Like"),
          ],
        ),
      ),
    );
  }
}

/// Icon-above-label action button, matching the K54 HOME PAGE Figma
/// frame's icon-over-label layout (node 571:714, "Frame 15357"). Label
/// combines the real count with its word ("12 Comments"/"Repost" when
/// zero) for Comment/Repost, and the static word "Send" for the
/// share-sheet trigger (which has no count concept).
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.jetBlack),
          // Same ~1px gap as _LikeButton above, for consistency.
          const SizedBox(height: 1),
          _AnimatedCount(value: label),
        ],
      ),
    );
  }
}

/// Fades/slides a count label in on change instead of an instant jump -
/// used for like/comment/share counts so an optimistic update or a
/// server reconciliation actually reads as something happening, not a
/// silent number swap. Harmless no-op for the static "Send" label, which
/// never changes.
class _AnimatedCount extends StatelessWidget {
  final String value;

  const _AnimatedCount({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: Text(
        value,
        key: ValueKey(value),
        style: const TextStyle(
          fontFamily: "Roboto",
          fontSize: 10,
          color: AppColors.jetBlack,
        ),
      ),
    );
  }
}

/// Real photo attachments from `bp_media_ids` (confirmed live 2026-07-19 -
/// see docs/api-audit/activity-feed.md). Single photo goes full-width like
/// the existing feature-image; 2+ show as a square grid, matching the
/// familiar social-feed pattern rather than a horizontal scroller, since
/// BuddyBoss's own web UI does the same for multi-photo posts.
class PostPhotosGrid extends StatelessWidget {
  final List<PostPhoto> photos;

  const PostPhotosGrid({super.key, required this.photos});

  void _openViewer(BuildContext context, int index) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: AppColors.black,
      pageBuilder: (_, _, _) => _PhotoViewerPage(photos: photos, initialIndex: index),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (photos.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: TapScale(
          onTap: () => _openViewer(context, 0),
          child: CachedNetworkImage(
            imageUrl: photos.first.imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              height: 250,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: AppColors.green),
            ),
            errorWidget: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: TapScale(
          onTap: () => _openViewer(context, index),
          child: CachedNetworkImage(
            imageUrl: photos[index].imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.greyShade200),
            errorWidget: (_, _, _) => Container(color: AppColors.greyShade200),
          ),
        ),
      ),
    );
  }
}

/// Full-screen swipeable photo viewer, opened on tap - a plain grid with no
/// way to see a photo at full size wouldn't be very usable once there's
/// more than one attached.
class _PhotoViewerPage extends StatelessWidget {
  final List<PostPhoto> photos;
  final int initialIndex;

  const _PhotoViewerPage({required this.photos, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          child: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: photos.length,
            itemBuilder: (context, index) => InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: photos[index].imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Real video attachments from `bp_videos` (confirmed live 2026-07-20 -
/// the `bb-video-preview/{token}/{token}` URL is a direct streamable
/// video/mp4 response, not an HTML player page). Deliberately doesn't
/// initialize the VideoPlayerController until the poster is tapped, so a
/// feed with several video posts doesn't open several network video
/// streams just from being scrolled past.
class PostVideoPlayer extends StatefulWidget {
  final PostVideo video;

  const PostVideoPlayer({super.key, required this.video});

  @override
  State<PostVideoPlayer> createState() => PostVideoPlayerState();
}

class PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;

  Future<void> _play() async {
    if (widget.video.videoUrl.isEmpty) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
      controller.play();
    } catch (_) {
      controller.dispose();
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: GestureDetector(
            onTap: () => setState(() {
              controller.value.isPlaying ? controller.pause() : controller.play();
            }),
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(controller),
                if (!controller.value.isPlaying)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow, color: AppColors.white, size: 32),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: TapScale(
        onTap: _loading ? null : _play,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: widget.video.posterUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.video.posterUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(color: AppColors.black87),
                    )
                  : Container(color: AppColors.black87),
            ),
            if (_loading)
              const CircularProgressIndicator(color: AppColors.white)
            else if (_failed)
              const Icon(Icons.error_outline, color: AppColors.white, size: 32)
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow, color: AppColors.white, size: 32),
              ),
            if (widget.video.durationLabel.isNotEmpty && !_loading)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)),
                  child: Text(widget.video.durationLabel, style: const TextStyle(color: AppColors.white, fontSize: 11)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Real document attachments from `bp_documents` (confirmed live
/// 2026-07-19). No in-app document viewer exists yet, so tapping opens
/// the real download URL externally rather than faking an in-app preview.
class PostDocumentTile extends StatelessWidget {
  final PostDocument document;

  const PostDocumentTile({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () {
        if (document.downloadUrl.isNotEmpty) {
          launchUrl(Uri.parse(document.downloadUrl), mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFECECEC)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.insert_drive_file_outlined, color: AppColors.green, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.jetBlack),
                  ),
                  if (document.size.isNotEmpty || document.extension.isNotEmpty)
                    Text(
                      [document.extension.toUpperCase(), document.size].where((s) => s.isNotEmpty).join(" · "),
                      style: TextStyle(fontSize: 11, color: AppColors.greyShade600),
                    ),
                ],
              ),
            ),
            const Icon(Icons.download_outlined, color: AppColors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Fetches and shows a post author's real professional-status text (e.g.
/// "Freelancer, Travel Blogger.") - see BuddyBossService.getUserProfession's
/// doc comment for why this can't just read post.profession directly.
/// Renders nothing while loading or if the author has no profession set,
/// rather than a loading spinner in the middle of the header row.
class _AuthorProfession extends StatelessWidget {
  final String userId;

  const _AuthorProfession({required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<String>(
      future: BuddyBossService().getUserProfession(userId),
      builder: (context, snapshot) {
        final profession = snapshot.data ?? "";
        if (profession.isEmpty) return const SizedBox.shrink();
        return Flexible(
          child: Text(
            profession,
            overflow: TextOverflow.ellipsis,
            // Poppins 12/400 #515050 - same Figma frame as the username
            // above it.
            style: GoogleFonts.poppins(color: const Color(0xFF515050), fontSize: 12),
          ),
        );
      },
    );
  }
}

/// Real deep link from a discussion-related Feed activity into the
/// actual thread - resolves the activity's topic/reply id to a real
/// Topic (see GroupsRepository.resolveDiscussionActivity's doc comment)
/// then opens it the same way the group's own Discussions tab does.
class _JoinDiscussionLink extends StatefulWidget {
  final String activityType;
  final String discussionId;

  const _JoinDiscussionLink({required this.activityType, required this.discussionId});

  @override
  State<_JoinDiscussionLink> createState() => _JoinDiscussionLinkState();
}

class _JoinDiscussionLinkState extends State<_JoinDiscussionLink> {
  bool _loading = false;

  Future<void> _open() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final resolved = await GroupsRepository.instance.resolveDiscussionActivity(
        activityType: widget.activityType,
        discussionId: widget.discussionId,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TopicDetailPage(topic: resolved.topic, forumId: resolved.forumId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't open discussion: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: _open,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
                )
              : const Icon(Icons.forum_outlined, size: 16, color: AppColors.green),
          const SizedBox(width: 6),
          Text(
            "Join Discussion",
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.green),
          ),
        ],
      ),
    );
  }
}

/// Real "someone is live" card, replacing the empty shell WPStream's own
/// activity template inserts (see Post.isLiveStreamActivity's doc comment -
/// that div only ever renders as a blank box in this app, since it needs
/// WPStream's own site JS to fill it). Polls the broadcaster's real
/// channel status (not just a one-time check on mount) so the card
/// reflects an ended stream as "ENDED" instead of staying stuck on "LIVE"
/// forever for a card that's been sitting in a scrolled feed - direct
/// tester feedback that it "always shows LIVE" was this exact gap.
class _LiveStreamCard extends StatefulWidget {
  final Post post;

  const _LiveStreamCard({required this.post});

  @override
  State<_LiveStreamCard> createState() => _LiveStreamCardState();
}

class _LiveStreamCardState extends State<_LiveStreamCard> {
  static const _pollInterval = Duration(seconds: 15);

  LiveChannelStatus? _status;
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final status = await LiveVideoRepository.instance.getStatusForUser(widget.post.userId);
      if (mounted) {
        setState(() {
          _status = status;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  void _open() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LiveWatchPage(post: widget.post)));
  }

  @override
  Widget build(BuildContext context) {
    final isLive = _status?.isLive ?? false;
    final poster = _status?.posterUrl ?? '';

    return TapScale(
      onTap: _open,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.jetBlack,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (poster.isNotEmpty)
                CachedNetworkImage(imageUrl: poster, fit: BoxFit.cover, errorWidget: (_, _, _) => const SizedBox.shrink())
              else
                Container(color: AppColors.jetBlack),
              Container(color: AppColors.black.withValues(alpha: 0.25)),
              if (_loading)
                const Center(child: CircularProgressIndicator(color: AppColors.white54))
              else
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                    child: Icon(isLive ? Icons.play_arrow : Icons.videocam_off_outlined, color: AppColors.white, size: 32),
                  ),
                ),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLive ? AppColors.error : AppColors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isLive ? "LIVE" : "ENDED",
                    style: GoogleFonts.lato(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  isLive ? "${widget.post.username} is live now - tap to watch" : "${widget.post.username}'s live stream has ended",
                  style: GoogleFonts.poppins(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
