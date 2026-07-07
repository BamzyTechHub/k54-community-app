import 'package:flutter/material.dart';

import '../controllers/inbox_controller.dart';
import '../models/message_thread_model.dart';
import '../repositories/messaging_repository.dart';
import 'chat_page.dart';
import 'new_conversation_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final InboxController _controller = InboxController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF008000),
        onPressed: () async {
          final started = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const NewConversationPage()),
          );
          if (started == true) _controller.load();
        },
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    "Messages",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _controller.load,
                    icon: const Icon(Icons.refresh, size: 26),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                onChanged: _controller.search,
                decoration: InputDecoration(
                  hintText: "Search conversations...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.loading && _controller.threads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.error != null && _controller.threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load messages.\n${_controller.error}",
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _controller.load, child: const Text("Retry")),
          ],
        ),
      );
    }

    final threads = _controller.threads;
    if (threads.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? "No conversations yet"
              : "No conversations match your search",
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: threads.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) => _threadTile(threads[index]),
      ),
    );
  }

  Future<void> _showThreadActions(MessageThread thread) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(thread.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(thread.isPinned ? "Unpin conversation" : "Pin conversation"),
              onTap: () => Navigator.pop(sheetContext, "pin"),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text("Erase conversation", style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(sheetContext, "erase"),
            ),
          ],
        ),
      ),
    );

    if (action == "pin") {
      await _togglePin(thread);
    } else if (action == "erase") {
      await _confirmErase(thread);
    }
  }

  Future<void> _togglePin(MessageThread thread) async {
    try {
      if (thread.isPinned) {
        await MessagingRepository.instance.unpinThread(thread.id);
      } else {
        await MessagingRepository.instance.pinThread(thread.id);
      }
      _controller.load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't update pin: $e")));
    }
  }

  Future<void> _confirmErase(MessageThread thread) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Erase conversation"),
        content: Text(
          "This can't be undone. Erase your conversation with ${thread.otherUserName}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Erase", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await MessagingRepository.instance.eraseThread(thread.id);
      _controller.load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't erase conversation: $e")));
    }
  }

  Widget _threadTile(MessageThread thread) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(threadId: thread.id, thread: thread),
          ),
        );
        _controller.load();
      },
      onLongPress: () => _showThreadActions(thread),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: thread.otherUserAvatar != null
                  ? NetworkImage(thread.otherUserAvatar!)
                  : null,
              child: thread.otherUserAvatar == null
                  ? Text(thread.otherUserName.isNotEmpty
                      ? thread.otherUserName[0].toUpperCase()
                      : "?")
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (thread.isPinned) ...[
                        Icon(Icons.push_pin, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          thread.otherUserName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: thread.isUnread ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    thread.lastMessagePreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: thread.isUnread ? Colors.black87 : Colors.grey,
                      fontWeight: thread.isUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(thread.lastMessageDate),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (thread.isUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF008000),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
