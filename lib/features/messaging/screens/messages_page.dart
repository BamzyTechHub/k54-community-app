import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/features/messaging/controllers/inbox_controller.dart';
import 'package:k54_mobile/features/messaging/models/message_thread_model.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
import 'package:k54_mobile/features/messaging/screens/chat_page.dart';
import 'package:k54_mobile/features/messaging/screens/new_conversation_page.dart';

/// Header matches the K54 Figma file's Messages screen exactly (node
/// 43:104): back button, title, then search/video_call/call/more_vert
/// icons - the same header component reused on Friends and Groups. Found
/// during the 2026-07-08 final parity pass to have drifted onto an older
/// large-title layout; rebuilt here. The floating "new conversation"
/// button and the inline search field are both real, working
/// functionality Figma's icon-only row doesn't visually account for, so
/// (per the same precedent used for Profile's Message button) they're
/// kept rather than removed to match the mockup literally.
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

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature is coming soon")),
    );
  }

  Future<void> _newConversation() async {
    final started = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NewConversationPage()),
    );
    if (started == true) _controller.load();
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return TapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.iconButtonBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppColors.jetBlack),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF008000),
        onPressed: _newConversation,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Column(
            children: [
              Row(
                children: [
                  _iconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  Text(
                    "Messages",
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.jetBlack,
                    ),
                  ),
                  const Spacer(),
                  TapScale(
                    onTap: () => _comingSoon("Search"),
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(Icons.search, size: 18, color: AppColors.jetBlack),
                  ),
                  const SizedBox(width: 10),
                  TapScale(
                    onTap: () => _comingSoon("More options"),
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(Icons.more_vert, size: 18, color: AppColors.jetBlack),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, index) => FadeSlideIn(
          key: ValueKey(threads[index].id),
          delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
          child: _threadTile(threads[index]),
        ),
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
