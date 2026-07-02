import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../services/buddyboss_service.dart';
import '../widgets/post_card.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

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

  void _loadTimeline() {
    _timelineFuture = _buddyBossService.getTimeline();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadTimeline();
    });

    await _timelineFuture;
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
              );
            },
          ),
        );
      },
    );
  }
}