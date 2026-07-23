import 'package:flutter/material.dart';

import 'package:k54_mobile/features/activity/models/post_model.dart';
import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/responsive.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/core/widgets/skeleton_loaders.dart';
import 'package:k54_mobile/core/widgets/state_views.dart';
import 'package:k54_mobile/features/activity/widgets/post_card.dart';

class TimelinePage extends StatefulWidget {
  final String? userId;

  const TimelinePage({
    super.key,
    this.userId,
  });

  @override
  State<TimelinePage> createState() => TimelinePageState();
}

class TimelinePageState extends State<TimelinePage> {
  final BuddyBossService _buddyBossService = BuddyBossService();
  final ScrollController _scrollController = ScrollController();

  late Future<List<Post>> _timelineFuture;
  List<Post> _posts = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant TimelinePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload when the profile being viewed actually changes - this
    // widget is held behind a stable GlobalKey (see HomePage), so
    // didUpdateWidget still fires on every unrelated parent rebuild even
    // though nothing about this widget's own props changed. Reloading
    // unconditionally threw away the optimistic prependPost() insert
    // (replaced _posts with a fresh page-1 fetch) every time that
    // happened, which is what made a just-created post flicker/disappear
    // and, combined with the pagination offset shifting underneath a
    // still-in-flight loadMore, made a post appear to show up twice.
    if (oldWidget.userId != widget.userId) {
      _loadTimeline();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  void _loadTimeline() {
    _timelineFuture = _buddyBossService
        .getTimeline(userId: widget.userId, page: 1)
        .then((posts) {
      _posts = posts;
      _page = 1;
      _hasMore = posts.isNotEmpty;
      return _posts;
    });
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final next = await _buddyBossService.getTimeline(
        userId: widget.userId,
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        if (next.isEmpty) {
          _hasMore = false;
        } else {
          _page += 1;
          // De-duped by id - a new post created between page loads shifts
          // BuddyBoss's offset-based pagination by one, so the post at the
          // old page boundary can come back again in the next page's
          // results. Without this, that post rendered twice in the feed
          // (reported live: "a test post appeared twice on the homepage").
          final existingIds = _posts.map((p) => p.id).toSet();
          final deduped = next.where((p) => !existingIds.contains(p.id));
          _posts = [..._posts, ...deduped];
        }
        _loadingMore = false;
      });
    } catch (_) {
      // Silent failure on a background page load - matches the same
      // convention used by CommentsSheet._loadMore for the same reason.
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadTimeline();
    });

    await _timelineFuture;
  }

  Future<void> refreshTimeline() async {
    await _refresh();
  }

  /// Inserts a freshly-created post at the top of the feed instantly,
  /// using the real Post object the create call already returned -
  /// deliberately NOT a re-fetch. A fresh post can take a noticeable
  /// while to show up in a subsequent `GET /buddyboss/v1/activity`
  /// response (server/CDN-side propagation delay, not a client bug), so
  /// waiting on a refetch to confirm "it worked" is exactly what made
  /// posting feel slow/uncertain - this shows the real result the
  /// moment the server confirms it, the same way Facebook's own feed
  /// inserts your post locally rather than waiting on its next feed
  /// fetch to notice it.
  void prependPost(Post post) {
    setState(() {
      _posts = [post, ..._posts];
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _timelineFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: 3,
            itemBuilder: (_, _) => const SkeletonPost(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(snapshot.error.toString()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: const [
                SizedBox(height: 100),
                K54EmptyState(icon: Icons.dynamic_feed_outlined, message: "No posts yet"),
              ],
            ),
          );
        }

        final posts = _posts;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: Center(
            child: ConstrainedBox(
              // Caps the feed at a readable width on tablets instead of
              // stretching single-column cards edge-to-edge - same pattern
              // already used by Friends/Groups/Members.
              constraints: BoxConstraints(maxWidth: Responsive.isTablet(context) ? 640 : double.infinity),
              child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20),
            // No separatorBuilder gap here - PostCard already carries its
            // own 10px top+bottom margin, which alone produces the exact
            // 20px gap the Figma feed specifies (autolayout gap=20) between
            // adjacent cards. Stacking a separator on top of that margin
            // was doubling the gap to ~28px, which is likely what read as
            // the feed looking like disconnected, floating cards instead
            // of a cohesive scroll.
            itemCount: posts.length + (_loadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= posts.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
                    ),
                  ),
                );
              }

              final post = posts[index];
              return FadeSlideIn(
                key: ValueKey(post.id),
                delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
                child: PostCard(
                post: post,
                onPostChanged: () {
                  // PostCard already mutates the Post object in place (like,
                  // pin, ...) on the same object held in this list (Dart
                  // objects are references, and FutureBuilder keeps
                  // returning the same List from its cached snapshot until
                  // the future itself changes), so this only needs to
                  // trigger a rebuild - re-fetching the whole feed here was
                  // the bug: it threw the FutureBuilder into a loading
                  // spinner and discarded the just-applied optimistic
                  // update on every like.
                  setState(() {});
                },
                onPostUpdated: (updated) {
                  // Edit changes several `final` fields at once, so unlike
                  // like/pin it can't be mutated in place - swap the list
                  // entry for the new object.
                  final index = posts.indexWhere((p) => p.id == updated.id);
                  if (index != -1) posts[index] = updated;
                  setState(() {});
                },
                onPostDeleted: () {
                  posts.removeWhere((p) => p.id == post.id);
                  setState(() {});
                },
                ),
              );
            },
              ),
            ),
          ),
        );
      },
    );
  }
}
