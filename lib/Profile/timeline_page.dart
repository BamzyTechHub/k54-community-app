import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../services/buddyboss_service.dart';
import '../widgets/post_card.dart';

class TimelinePage extends StatefulWidget {
  final String? userId;

  const TimelinePage({
    super.key,
    this.userId,
  });

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
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
          return const Center(
            child: CircularProgressIndicator(),
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
                SizedBox(height: 250),
                Center(
                  child: Text(
                    "No posts available",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        }

        final posts = _posts;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: posts.length + (_loadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index >= posts.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final post = posts[index];
              return PostCard(
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
              );
            },
          ),
        );
      },
    );
  }
}
