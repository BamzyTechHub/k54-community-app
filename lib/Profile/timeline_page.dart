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

  late Future<List<Post>> _timelineFuture;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }
  @override
void didUpdateWidget(covariant TimelinePage oldWidget) {
  super.didUpdateWidget(oldWidget);

  _loadTimeline();
}

  void _loadTimeline() {
  _timelineFuture = _buddyBossService.getTimeline(
    userId: widget.userId,
  );
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

        final posts = snapshot.data!;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
               return PostCard(
  post: posts[index],
  onPostChanged: () {
    // PostCard already mutates the Post object in place (like, pin, ...)
    // on the same object held in this list (Dart objects are references),
    // so this only needs to trigger a rebuild — re-fetching the whole feed
    // here was the bug: it threw the FutureBuilder into a loading spinner
    // and discarded the just-applied optimistic update on every like.
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