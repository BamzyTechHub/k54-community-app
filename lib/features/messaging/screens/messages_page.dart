import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/k54_route.dart';
import 'package:k54_mobile/core/utils/responsive.dart';
import 'package:k54_mobile/core/widgets/contact_row.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/k54_search_field.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/core/widgets/skeleton_loaders.dart';
import 'package:k54_mobile/core/widgets/state_views.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/features/messaging/controllers/inbox_controller.dart';
import 'package:k54_mobile/features/messaging/models/message_thread_model.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
import 'package:k54_mobile/features/messaging/screens/chat_page.dart';
import 'package:k54_mobile/features/messaging/screens/new_conversation_page.dart';

/// Header re-verified directly against the raw node 43:104 JSON,
/// 2026-07-16: back button, title (Lato 16/700, was wrongly 20 before),
/// then ONLY a search icon - no video_call/call/more_vert icons exist in
/// this frame at all (that was an assumption from an earlier pass,
/// carried over from Friends/Groups' header instead of verified against
/// Messages' own data). Those two icons were also pure "_comingSoon"
/// stubs with no real behavior, so removing them is a straight
/// improvement, not a functionality loss. The header search icon now
/// focuses the real K54SearchField below instead of showing its own fake
/// "coming soon" snackbar next to a search field that actually works.
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final InboxController _controller = InboxController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // The search field only appears after tapping the search icon (was
  // permanently visible before, which isn't what the real header does -
  // it collapses again once the field loses focus with nothing typed in
  // it, same pattern as a standard mobile search bar).
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _controller.load();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
        setState(() => _searchExpanded = false);
      }
    });
  }

  void _openSearch() {
    setState(() => _searchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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

  Future<void> _newConversation() async {
    final started = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NewConversationPage()),
    );
    if (started == true) _controller.load();
  }

  // Figma's Messages header (node 43:104) matches Groups/Friends' shared
  // header component exactly: plain icons, no circular chip background.
  Widget _plainIcon({required IconData icon, required VoidCallback onTap, double size = 22}) {
    return TapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: size, color: AppColors.jetBlack),
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
                  _plainIcon(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
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
                  _plainIcon(icon: Icons.search, onTap: _openSearch),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: _searchExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: K54SearchField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _controller.search,
                          hintText: "Search conversations...",
                        ),
                      )
                    : const SizedBox(width: double.infinity),
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
      return const SkeletonRowList();
    }
    if (_controller.error != null && _controller.threads.isEmpty) {
      return K54ErrorState(
        message: "Couldn't load messages.\n${_controller.error}",
        onRetry: _controller.load,
      );
    }

    final threads = _controller.threads;
    if (threads.isEmpty) {
      return K54EmptyState(
        icon: Icons.chat_bubble_outline,
        message: _searchController.text.isEmpty
            ? "No conversations yet"
            : "No conversations match your search",
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: Center(
        child: ConstrainedBox(
          // Caps the list at a readable width on tablets instead of
          // stretching rows edge-to-edge - same pattern already used by
          // Friends/Groups/Members.
          constraints: BoxConstraints(maxWidth: Responsive.isTablet(context) ? 640 : double.infinity),
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
        ),
      ),
    );
  }

  Future<void> _showThreadActions(MessageThread thread) async {
    final action = await showK54BottomSheet<String>(
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
        shape: K54Dialog.shape,
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
    return ContactRow(
      avatarUrl: thread.otherUserAvatar,
      isOnline: thread.otherUserOnline,
      title: thread.otherUserName,
      titleStyle: TextStyle(fontSize: 17, fontWeight: thread.isUnread ? FontWeight.bold : FontWeight.w600),
      titlePrefix: thread.isPinned ? Icon(Icons.push_pin, size: 13, color: Colors.grey.shade500) : null,
      subtitle: thread.lastMessagePreview,
      onTap: () async {
        await Navigator.push(
          context,
          k54Route(ChatPage(threadId: thread.id, thread: thread)),
        );
        _controller.load();
      },
      onLongPress: () => _showThreadActions(thread),
      // Time/badge colors and sizes match the Messages frame (node
      // 43:104) exactly, pulled via the REST API 2026-07-16 - was grey/
      // olive/20px before this measurement existed.
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(thread.lastMessageDate),
            style: const TextStyle(color: AppColors.jetBlack, fontSize: 10),
          ),
          if (thread.isUnread) ...[
            const SizedBox(height: 6),
            Container(
              width: 14,
              height: 14,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
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
}
