import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';

import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/core/utils/open_profile.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/core/widgets/skeleton_loaders.dart';
import 'package:k54_mobile/core/widgets/state_views.dart';
import 'package:k54_mobile/features/activity/widgets/comments_sheet.dart';
import 'package:k54_mobile/features/friends/screens/friends_page.dart';
import 'package:k54_mobile/features/groups/screens/group_detail_page.dart';
import 'package:k54_mobile/features/messaging/screens/chat_page.dart';
import 'package:k54_mobile/features/notifications/controllers/notifications_controller.dart';
import 'package:k54_mobile/features/notifications/models/app_notification.dart';

/// Wired to the confirmed `/buddyboss/v1/notifications` REST surface
/// (see app_notification.dart's doc comment). No Figma reference exists
/// for this screen, so the existing visual layout is kept as-is per the
/// "prioritize functionality over cosmetic polish" rule - only the data
/// source changed, from a hardcoded dummy list to the real API.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationsController _controller = NotificationsController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago";
    if (diff.inDays < 7) return "${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago";
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Notifications",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _controller.unreadCount == 0 ? null : _controller.markAllRead,
                    child: const Text("Mark all read"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.loading && _controller.notifications.isEmpty) {
      return const SkeletonRowList();
    }
    if (_controller.error != null && _controller.notifications.isEmpty) {
      return K54ErrorState(
        message: "Couldn't load notifications.\n${_controller.error}",
        onRetry: _controller.load,
      );
    }
    if (_controller.notifications.isEmpty) {
      return const K54EmptyState(icon: Icons.notifications_none, message: "No notifications yet");
    }

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView.builder(
        itemCount: _controller.notifications.length,
        itemBuilder: (context, index) {
          final notification = _controller.notifications[index];
          return FadeSlideIn(
            key: ValueKey(notification.id),
            delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
            child: _notificationTile(notification),
          );
        },
      ),
    );
  }

  /// Routes a tapped notification to whatever real content it's about,
  /// using BuddyPress/BuddyBoss's standard `item_id`/`secondary_item_id`
  /// conventions for each component (well-established open-source
  /// behavior, not guessed): messages -> item_id is the thread id;
  /// friends -> item_id is the friendship id, secondary_item_id is the
  /// other user's id; groups -> item_id is the group id. The `activity`
  /// mapping (item_id = the activity/post id) is confirmed directly
  /// against this site's own live notifications this session.
  Future<void> _openNotification(AppNotification notification) async {
    _controller.markRead(notification);

    switch (notification.component) {
      case 'messages':
        if (notification.itemId.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatPage(threadId: notification.itemId)),
        );
        break;

      case 'activity':
        if (notification.itemId.isEmpty) return;
        try {
          final post = await BuddyBossService().getActivity(notification.itemId);
          if (!mounted) return;
          CommentsSheet.show(context, post);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Couldn't open this post: $e")),
            );
          }
        }
        break;

      case 'friends':
        if (notification.secondaryItemId != null && notification.secondaryItemId!.isNotEmpty) {
          openProfile(context, notification.secondaryItemId!);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsPage()));
        }
        break;

      case 'groups':
        if (notification.itemId.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupDetailPage(groupId: notification.itemId)),
        );
        break;

      default:
        // Unrecognized component - nothing confirmed to route to, so this
        // just leaves the notification marked read rather than guessing a
        // destination.
        break;
    }
  }

  Widget _notificationTile(AppNotification notification) {
    return InkWell(
      onTap: () => _openNotification(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: notification.isNew ? const Color(0xFFE8F5E9) : const Color(0xFFF5EFD9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: notification.displayColor,
              child: Icon(notification.displayIcon, color: AppColors.white),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.displayText, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(_relativeTime(notification.date), style: const TextStyle(color: AppColors.grey)),
                ],
              ),
            ),
            if (notification.isNew)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
