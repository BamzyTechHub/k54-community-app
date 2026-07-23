import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:k54_mobile/features/activity/models/comment_model.dart';
import 'package:k54_mobile/features/activity/models/post_model.dart';
import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/core/utils/open_profile.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';

/// Facebook-pattern comment sheet (list + fixed composer + inline replies),
/// restyled with K54's own colors/typography/radii so it reads as part of
/// this app rather than a copied screen. No dedicated Figma reference exists
/// for this screen - built from the UX pattern + K54's existing design
/// language observed elsewhere in the app (post_card.dart in particular).
class CommentsSheet extends StatefulWidget {
  final Post post;
  final VoidCallback? onPostChanged;

  const CommentsSheet({super.key, required this.post, this.onPostChanged});

  static Future<void> show(BuildContext context, Post post, {VoidCallback? onPostChanged}) {
    return showK54BottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CommentsSheet(post: post, onPostChanged: onPostChanged),
    );
  }

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  static const _brandGreen = Color(0xFF008000);
  static const _cardBackground = Color(0xFFF5EFD9);

  final BuddyBossService _service = BuddyBossService();
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _composerFocus = FocusNode();

  List<Comment>? _comments;
  bool _loading = true;
  Object? _error;
  bool _sending = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  Comment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _composerController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final comments = await _service.getComments(widget.post.id, page: 1);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _page = 1;
        _hasMore = comments.isNotEmpty;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final next = await _service.getComments(widget.post.id, page: _page + 1);
      if (!mounted) return;
      setState(() {
        if (next.isEmpty) {
          _hasMore = false;
        } else {
          _page += 1;
          _comments = [...?_comments, ...next];
        }
        _loadingMore = false;
      });
    } catch (_) {
      // Silent failure on a background page load - matches this app's
      // existing convention (see ChatController._pollOnce) of not
      // interrupting the user for a transient load-more hiccup.
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final replyTarget = _replyingTo;
    try {
      final comment = await _service.postComment(
        activityId: widget.post.id,
        content: text,
        replyToCommentId: replyTarget?.id,
      );
      if (!mounted) return;
      setState(() {
        if (replyTarget != null) {
          replyTarget.replies.add(comment);
        } else {
          _comments = [...?_comments, comment];
        }
        _composerController.clear();
        _replyingTo = null;
        _sending = false;
      });
      // The post card underneath (and the count on it) is a separate
      // widget from this sheet - without this callback, a successfully
      // posted comment would show up in the sheet's own list but the
      // count on the feed card behind it would never move.
      widget.post.comments += 1;
      widget.onPostChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't post comment: $e")),
      );
    }
  }

  Future<void> _toggleLike(Comment comment) async {
    final wasLiked = comment.isLiked;
    final previousCount = comment.likeCount;
    setState(() {
      comment.isLiked = !wasLiked;
      comment.likeCount += wasLiked ? -1 : 1;
    });
    try {
      final updated = await _service.toggleCommentFavorite(comment.id);
      if (!mounted) return;
      setState(() {
        comment.isLiked = updated.isLiked;
        comment.likeCount = updated.likeCount;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        comment.isLiked = wasLiked;
        comment.likeCount = previousCount;
      });
    }
  }

  void _openCommentAuthor(Comment comment) {
    if (comment.userId.isEmpty) return;
    openProfile(context, comment.userId);
  }

  void _startReply(Comment comment) {
    if (widget.post.commentsClosed) return;
    setState(() => _replyingTo = comment);
    _composerFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        top: false,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              _buildHeader(),
              const Divider(height: 1),
              Expanded(child: _buildBody()),
              if (!widget.post.commentsClosed && _replyingTo != null)
                _buildReplyBanner(),
              const Divider(height: 1),
              widget.post.commentsClosed
                  ? _buildClosedNotice()
                  : _buildComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.greyShade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Comments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _brandGreen));
    }

    if (_error != null && (_comments == null || _comments!.isEmpty)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load comments.\n$_error", textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadComments, child: const Text("Retry")),
          ],
        ),
      );
    }

    final comments = _comments ?? [];
    if (comments.isEmpty) {
      return RefreshIndicator(
        color: _brandGreen,
        onRefresh: _loadComments,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text("No comments yet — be the first to reply.")),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _brandGreen,
      onRefresh: _loadComments,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: comments.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= comments.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _brandGreen),
                ),
              ),
            );
          }
          return _buildCommentTile(comments[index]);
        },
      ),
    );
  }

  Widget _buildCommentTile(Comment comment, {bool isReply = false}) {
    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 44 : 0,
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TapScale(
            onTap: () => _openCommentAuthor(comment),
            borderRadius: BorderRadius.circular(isReply ? 14 : 18),
            child: UserAvatar(
              imageUrl: null,
              imageProvider:
                  comment.userAvatar.isNotEmpty ? CachedNetworkImageProvider(comment.userAvatar) : null,
              name: comment.userName,
              radius: isReply ? 14 : 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _cardBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _openCommentAuthor(comment),
                        child: Text(
                          comment.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(comment.content, style: const TextStyle(fontSize: 14, height: 1.35)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Text(
                        _relativeTime(comment.createdAt),
                        style: TextStyle(fontSize: 11, color: AppColors.greyShade600),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => _toggleLike(comment),
                        child: Text(
                          "Like${comment.likeCount > 0 ? ' (${comment.likeCount})' : ''}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: comment.isLiked ? AppColors.error : AppColors.greyShade600,
                          ),
                        ),
                      ),
                      if (!widget.post.commentsClosed) ...[
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () => _startReply(comment),
                          child: Text(
                            "Reply",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.greyShade600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (comment.replies.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...comment.replies.map((r) => _buildCommentTile(r, isReply: true)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBanner() {
    return Container(
      width: double.infinity,
      color: _cardBackground,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Replying to ${_replyingTo!.userName}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _replyingTo = null),
            child: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: _cardBackground,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _composerController,
                focusNode: _composerFocus,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _submitComment(),
                decoration: InputDecoration(
                  hintText: _replyingTo != null ? "Write a reply..." : "Write a comment...",
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sending ? null : _submitComment,
            icon: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _brandGreen),
                  )
                : const Icon(Icons.send_rounded, color: _brandGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.comments_disabled_outlined,
              size: 16, color: AppColors.greyShade600),
          const SizedBox(width: 8),
          Text(
            "Comments are closed for this post",
            style: TextStyle(fontSize: 13, color: AppColors.greyShade600),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";
    return "${date.day}/${date.month}/${date.year}";
  }
}
