import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemSound, SystemSoundType, HapticFeedback;

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/open_profile.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';
import 'package:k54_mobile/features/messaging/controllers/chat_controller.dart';
import 'package:k54_mobile/features/messaging/models/chat_message_model.dart';
import 'package:k54_mobile/features/messaging/models/message_thread_model.dart';
import 'package:k54_mobile/features/messaging/widgets/emoji_picker_sheet.dart';

class ChatPage extends StatefulWidget {
  final String threadId;
  final MessageThread? thread; // optional preview data from the inbox list

  const ChatPage({super.key, required this.threadId, this.thread});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _controller;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = ChatController(threadId: widget.threadId, initialThread: widget.thread);
    _controller.addListener(_onControllerChanged);
    _init();
  }

  Future<void> _init() async {
    await _controller.load();
    // The page may have been popped while load() was awaiting its network
    // call — ChatController guards its own notifyListeners() calls against
    // that, but this method must not act any further either: touching
    // _scrollController here would use it after dispose(), and calling
    // startPolling() would start a new Timer.periodic on a controller
    // that's already disposed and will never be disposed again.
    if (!mounted) return;
    _scrollToBottom();
    _controller.startPolling(); // stops automatically in dispose()
  }

  void _onControllerChanged() {
    setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    _messageController.clear();
    final ok = await _controller.send(text);
    if (ok) {
      // Real audible feedback that the message went out. This is the
      // platform's own short UI click sound, not a custom "sent.mp3" tone
      // - the real Better Messages sound assets (docs/api-audit mentions
      // notification.mp3/sent.mp3) live on the plugin's own site bundle,
      // which isn't something this app can fetch/redistribute. If you'd
      // like the exact sound, drop the file into assets/sounds/ and this
      // can switch to playing it directly instead.
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
      _scrollToBottom();
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to send: ${_controller.error}")));
      _messageController.text = text;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose(); // cancels the polling timer
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thread = _controller.thread;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(thread),
            const Divider(height: 1),
            Expanded(child: _buildMessages(thread)),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MessageThread? thread) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 28),
          ),
          // Tapping the avatar or name opens the other user's real
          // profile page - previously dead, no onTap at all.
          Expanded(
            child: TapScale(
              onTap: thread == null || thread.otherUserId.isEmpty
                  ? null
                  : () => openProfile(context, thread.otherUserId),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  UserAvatar(
                    imageUrl: thread?.otherUserAvatar,
                    name: thread?.otherUserName ?? "",
                    radius: 22,
                    isOnline: thread?.otherUserOnline,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          thread?.otherUserName ?? "Loading...",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        // Real presence, not decorative - see
                        // MessageThread.otherUserOnline's doc comment.
                        if (thread != null)
                          Text(
                            thread.otherUserOnline ? "Online" : "Offline",
                            style: TextStyle(
                              fontSize: 12,
                              color: thread.otherUserOnline ? AppColors.green : Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _comingSoon("Search"),
            icon: const Icon(Icons.search, size: 22),
          ),
          IconButton(
            onPressed: () => _comingSoon("Video call"),
            icon: const Icon(Icons.video_call_outlined, size: 22),
          ),
          IconButton(
            onPressed: () => _comingSoon("Voice call"),
            icon: const Icon(Icons.call_outlined, size: 22),
          ),
        ],
      ),
    );
  }

  void _openEmojiPicker() {
    showEmojiPickerSheet(
      context: context,
      onSelected: (emoji) {
        final selection = _messageController.selection;
        final text = _messageController.text;
        final insertAt = selection.start >= 0 ? selection.start : text.length;
        final newText = text.replaceRange(insertAt, selection.end >= 0 ? selection.end : insertAt, emoji);
        _messageController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: insertAt + emoji.length),
        );
        setState(() {});
      },
    );
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature is coming soon")),
    );
  }

  Widget _buildMessages(MessageThread? thread) {
    if (_controller.loading && thread == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_controller.error != null && thread == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load conversation.\n${_controller.error}",
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _controller.load, child: const Text("Retry")),
          ],
        ),
      );
    }

    final messages = _controller.messages;
    if (messages.isEmpty) {
      return const Center(child: Text("Say hello 👋"));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(15),
      itemCount: messages.length,
      itemBuilder: (context, index) => FadeSlideIn(
        key: ValueKey(messages[index].id),
        child: _buildBubble(messages[index]),
      ),
    );
  }

  Widget _buildBubble(ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              // Exact bubble colors from the Chat Figma frame (node
              // 61:2448), pulled via the REST API 2026-07-16 - was
              // groupCardAccent/groupCardBackground (a darker green/tan
              // pair) before this measurement existed. Both old colors
              // were dark enough to read as visually similar at a glance,
              // which may be what was reported as "no difference between
              // sender and receiver."
              color: message.isMe ? const Color(0xFFB4D69E) : const Color(0xFFFCF8ED),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(message.isMe ? 18 : 0),
                bottomRight: Radius.circular(message.isMe ? 0 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.hasAttachment) _buildAttachments(message),
                if (message.message.isNotEmpty) ...[
                  if (message.hasAttachment) const SizedBox(height: 8),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: message.isMe ? Colors.white : Colors.black,
                      fontSize: 15,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.favorited) ...[
                      Icon(
                        Icons.star,
                        size: 13,
                        color: message.isMe ? Colors.white70 : Colors.amber.shade700,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      "${message.date.hour.toString().padLeft(2, '0')}:${message.date.minute.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        color: message.isMe ? Colors.white70 : Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (message.reactions.isNotEmpty) _buildReactions(message),
        ],
      ),
    );
  }

  Widget _buildAttachments(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: message.files.map((file) {
        if (file.isImage) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                file.thumbUrl.isNotEmpty ? file.thumbUrl : file.url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insert_drive_file,
                    size: 16, color: message.isMe ? Colors.white : Colors.black87),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    file.name.isNotEmpty ? file.name : "Attachment",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: message.isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReactions(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          message.reactions.join(" "),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.groupCardAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  TapScale(
                    onTap: _openEmojiPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(Icons.emoji_emotions_outlined, size: 20, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: "Message",
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  // Deliberately still "coming soon", not wired to a local
                  // image_picker/file_picker call - Better Messages does
                  // have real upload endpoints (`thread/{id}/upload`,
                  // `thread/{id}/attachments`, confirmed to exist in
                  // docs/api-audit/messaging-better-messages.md), but their
                  // exact multipart request shape was never captured. A
                  // local-only pick that can't actually reach the send
                  // endpoint would show the photo on this device and
                  // nothing on the other end - guessing at the multipart
                  // body risks exactly that silent one-sided failure.
                  // Worth a HAR capture of a real upload from the website
                  // to unlock this for real.
                  TapScale(
                    onTap: () => _comingSoon("Attaching a file"),
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(Icons.attach_file, size: 20, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 6),
                  TapScale(
                    onTap: () => _comingSoon("Camera"),
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(Icons.camera_alt_outlined, size: 20, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          TapScale(
            onTap: _controller.sending
                ? null
                : (_messageController.text.trim().isEmpty
                    ? () => _comingSoon("Voice messages")
                    : _send),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _controller.sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(
                        _messageController.text.trim().isEmpty ? Icons.mic : Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
