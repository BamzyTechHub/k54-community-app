import 'package:flutter/material.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/k54_route.dart';
import 'package:k54_mobile/core/widgets/contact_row.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/core/widgets/skeleton_loaders.dart';
import 'package:k54_mobile/core/widgets/state_views.dart';
import 'package:k54_mobile/features/messaging/controllers/inbox_controller.dart';
import 'package:k54_mobile/features/messaging/models/message_thread_model.dart';
import 'package:k54_mobile/features/messaging/screens/chat_page.dart';

/// Just the thread rows from MessagesPage, no header/search/FAB - for
/// embedding inline (Profile's "Messages" tab) rather than as its own
/// full screen. Same real InboxController/thread-tap-to-chat behavior,
/// just without the page chrome that doesn't make sense nested inside
/// another scrollable page.
class MessagesInboxList extends StatefulWidget {
  const MessagesInboxList({super.key});

  @override
  State<MessagesInboxList> createState() => _MessagesInboxListState();
}

class _MessagesInboxListState extends State<MessagesInboxList> {
  final InboxController _controller = InboxController();

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

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      return "$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}";
    }
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _threadTile(MessageThread thread) {
    return ContactRow(
      avatarUrl: thread.otherUserAvatar,
      isOnline: thread.otherUserOnline,
      title: thread.otherUserName,
      titleStyle: TextStyle(fontSize: 17, fontWeight: thread.isUnread ? FontWeight.bold : FontWeight.w600),
      titlePrefix: thread.isPinned ? Icon(Icons.push_pin, size: 13, color: Colors.grey.shade500) : null,
      subtitle: thread.lastMessagePreview,
      onTap: () async {
        await Navigator.push(context, k54Route(ChatPage(threadId: thread.id, thread: thread)));
        _controller.load();
      },
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_formatTime(thread.lastMessageDate), style: const TextStyle(color: AppColors.jetBlack, fontSize: 10)),
          if (thread.isUnread) ...[
            const SizedBox(height: 6),
            Container(
              width: 14,
              height: 14,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
              child: Text(
                "${thread.unreadCount}",
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.loading && _controller.threads.isEmpty) {
      return const SkeletonRowList();
    }
    if (_controller.error != null && _controller.threads.isEmpty) {
      return K54ErrorState(message: "Couldn't load messages.\n${_controller.error}", onRetry: _controller.load);
    }
    final threads = _controller.threads;
    if (threads.isEmpty) {
      return const K54EmptyState(icon: Icons.chat_bubble_outline, message: "No conversations yet");
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: threads.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) => FadeSlideIn(
        key: ValueKey(threads[index].id),
        delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
        child: _threadTile(threads[index]),
      ),
    );
  }
}
