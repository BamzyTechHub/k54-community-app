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
    _loadTimeline();
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
          _posts = [..._posts, ...next];
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
