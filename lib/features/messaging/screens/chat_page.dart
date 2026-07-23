import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemSound, SystemSoundType, HapticFeedback, Clipboard, ClipboardData;
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/open_profile.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';
import 'package:k54_mobile/features/messaging/calling/call_screen.dart';
import 'package:k54_mobile/features/messaging/controllers/chat_controller.dart';
import 'package:k54_mobile/features/messaging/models/chat_message_model.dart';
import 'package:k54_mobile/features/messaging/models/message_thread_model.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
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

  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;

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
    _recorder.dispose();
    super.dispose();
  }

  /// Voice notes are a real, confirmed two-step flow (upload the file,
  /// then reference the returned attachment id via sendVoice - see
  /// ChatController.sendVoiceNote's doc comment), not a "coming soon"
  /// stub. Recording itself is a genuine mic capture via the `record`
  /// package, not a fake progress bar.
  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission is needed to record a voice message")),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a";
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    HapticFeedback.mediumImpact();
    setState(() => _recording = true);
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_recording) return;
    final path = await _recorder.stop();
    setState(() => _recording = false);
    if (path == null) return;

    final file = File(path);
    // A press that was too short to be a real voice note (accidental tap)
    // - don't send a near-silent fraction-of-a-second clip.
    if (!await file.exists() || await file.length() < 500) {
      return;
    }

    final ok = await _controller.sendVoiceNote(file);
    if (ok) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
      _scrollToBottom();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send voice message: ${_controller.error}")),
      );
    }
  }

  Future<void> _cancelRecording() async {
    if (!_recording) return;
    await _recorder.cancel();
    setState(() => _recording = false);
  }

  /// Real image attach, confirmed live 2026-07-20 via a disposable-
  /// message test (see ChatController.sendFileMessage's doc comment) -
  /// upload then reference via `send`'s `files` param. Only images are
  /// wired (via image_picker, already a dependency) - arbitrary documents
  /// would need a separate file_picker package addition, out of scope for
  /// this pass.
  Future<void> _pickAndSendImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    final ok = await _controller.sendFileMessage(File(picked.path));
    if (ok) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
      _scrollToBottom();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send image: ${_controller.error}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = _controller.thread;
    return Scaffold(
      backgroundColor: AppColors.white,
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
                    isOnline: thread != null && !thread.isGroupThread ? thread.otherUserOnline : null,
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
                        // Real presence for a 1-on-1 thread - see
                        // MessageThread.otherUserOnline's doc comment. A
                        // group thread has no single "online" person, so
                        // this shows the real participant count instead
                        // (confirmed live 2026-07-22, `type: "group"`
                        // threads carry a real `participantsCount`).
                        if (thread != null)
                          Text(
                            thread.isGroupThread ? "${thread.participantCount} participants" : (thread.otherUserOnline ? "Online" : "Offline"),
                            style: TextStyle(
                              fontSize: 12,
                              color: thread.isGroupThread
                                  ? AppColors.greyShade600
                                  : (thread.otherUserOnline ? AppColors.green : AppColors.grey),
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
            onPressed: thread == null ? null : () => _startCall(thread, isVideo: true),
            icon: const Icon(Icons.video_call_outlined, size: 22),
          ),
          IconButton(
            onPressed: thread == null ? null : () => _startCall(thread, isVideo: false),
            icon: const Icon(Icons.call_outlined, size: 22),
          ),
        ],
      ),
    );
  }

  // Real call - wired 2026-07-22 against the confirmed Better
  // Messages callCreate/LiveKit flow (see CallController's doc comment).
  // Only reaches whoever's on the other end while they're actually
  // looking at this thread right now - there's no push-notification or
  // background-signaling layer in this app yet, so a genuine "ringing"
  // experience for the callee isn't there. Real for the caller's side
  // end-to-end either way.
  void _startCall(MessageThread thread, {required bool isVideo}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          threadId: thread.id,
          otherUserName: thread.otherUserName,
          otherUserAvatar: thread.otherUserAvatar,
          isVideo: isVideo,
        ),
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
      child: GestureDetector(
        onLongPress: () => _openMessageMenu(message),
        child: Column(
          crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.isPinned)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.push_pin, size: 11, color: AppColors.greyShade600),
                    const SizedBox(width: 3),
                    Text("Pinned", style: TextStyle(fontSize: 11, color: AppColors.greyShade600)),
                  ],
                ),
              ),
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
                  if (message.isVoiceNote)
                    _VoiceMessageBubble(url: message.voiceUrl, isMe: message.isMe)
                  else ...[
                    if (message.hasAttachment) _buildAttachments(message),
                    if (message.message.isNotEmpty) ...[
                      if (message.hasAttachment) const SizedBox(height: 8),
                      Text(
                        message.message,
                        style: TextStyle(
                          color: message.isMe ? AppColors.white : AppColors.black,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.favorited) ...[
                        Icon(
                          Icons.star,
                          size: 13,
                          color: message.isMe ? AppColors.white70 : AppColors.amber,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        "${message.date.hour.toString().padLeft(2, '0')}:${message.date.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(
                          color: message.isMe ? AppColors.white70 : AppColors.grey,
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
      ),
    );
  }

  Future<void> _openMessageMenu(ChatMessage message) async {
    final canCopy = !message.isVoiceNote && message.message.isNotEmpty;
    final action = await showK54BottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canCopy)
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text("Copy text"),
                onTap: () => Navigator.pop(sheetContext, "copy"),
              ),
            ListTile(
              leading: const Icon(Icons.forward_outlined),
              title: const Text("Forward"),
              onTap: () => Navigator.pop(sheetContext, "forward"),
            ),
            ListTile(
              leading: Icon(message.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(message.isPinned ? "Unpin message" : "Pin message"),
              onTap: () => Navigator.pop(sheetContext, "pin"),
            ),
            if (message.isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text("Delete message", style: TextStyle(color: AppColors.error)),
                onTap: () => Navigator.pop(sheetContext, "delete"),
              ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    switch (action) {
      case "copy":
        Clipboard.setData(ClipboardData(text: message.message));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied")));
        break;
      case "forward":
        await _forwardMessage(message);
        break;
      case "pin":
        if (message.isPinned) {
          await _controller.unpinMessage(message.id);
        } else {
          await _controller.pinMessage(message.id);
        }
        break;
      case "delete":
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: K54Dialog.shape,
            title: const Text("Delete message"),
            content: const Text("This can't be undone. Delete this message?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("Delete", style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          final ok = await _controller.deleteMessage(message.id);
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Couldn't delete message: ${_controller.error}")),
            );
          }
        }
        break;
    }
  }

  Future<void> _forwardMessage(ChatMessage message) async {
    // Every other thread this user has, so they can pick where to forward
    // to - loaded from the repo's inbox cache (already populated by the
    // time a chat is open; refreshed here in case it's stale/empty).
    var threads = MessagingRepository.instance.cachedThreads;
    if (threads.isEmpty) {
      try {
        threads = await MessagingRepository.instance.refreshThreads();
      } catch (_) {
        threads = const [];
      }
    }
    final otherThreads = threads.where((t) => t.id != widget.threadId).toList();

    if (!mounted) return;
    if (otherThreads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No other conversations to forward to")),
      );
      return;
    }

    final target = await showK54BottomSheet<MessageThread>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text("Forward to...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherThreads.length,
                  itemBuilder: (context, index) {
                    final t = otherThreads[index];
                    return ListTile(
                      leading: UserAvatar(imageUrl: t.otherUserAvatar, name: t.otherUserName, radius: 18),
                      title: Text(t.otherUserName),
                      onTap: () => Navigator.pop(sheetContext, t),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (target == null || !mounted) return;
    final ok = await _controller.forwardMessage(message.id, [target.id]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? "Forwarded to ${target.otherUserName}" : "Couldn't forward: ${_controller.error}")),
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
              color: AppColors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insert_drive_file,
                    size: 16, color: message.isMe ? AppColors.white : AppColors.black87),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    file.name.isNotEmpty ? file.name : "Attachment",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: message.isMe ? AppColors.white : AppColors.black87,
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyShade300),
        ),
        child: Text(
          message.reactions.join(" "),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    if (_recording) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            TapScale(
              onTap: _cancelRecording,
              borderRadius: BorderRadius.circular(20),
              child: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.mic, color: AppColors.green, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text("Recording voice message...", style: TextStyle(color: AppColors.grey)),
            ),
            TapScale(
              onTap: _stopRecordingAndSend,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                child: const Icon(Icons.send, color: AppColors.white, size: 20),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.groupCardAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  TapScale(
                    onTap: _openEmojiPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(Icons.emoji_emotions_outlined, size: 20, color: AppColors.greyShade600),
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
                        focusedBorder: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  // Real image attach, confirmed live 2026-07-20 (see
                  // _pickAndSendImage's doc comment) - the exact multipart
                  // shape (`thread/{id}/upload` field `file`, then `send`
                  // with `files: [id]`) was found via a disposable-message
                  // test. Arbitrary non-image files still aren't wired -
                  // that needs a file_picker package addition.
                  TapScale(
                    onTap: () => _pickAndSendImage(ImageSource.gallery),
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(Icons.attach_file, size: 20, color: AppColors.greyShade600),
                  ),
                  const SizedBox(width: 6),
                  TapScale(
                    onTap: () => _pickAndSendImage(ImageSource.camera),
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.greyShade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onLongPressStart: _messageController.text.trim().isEmpty && !_controller.sending
                ? (_) => _startRecording()
                : null,
            onLongPressEnd: _messageController.text.trim().isEmpty ? (_) => _stopRecordingAndSend() : null,
            onTap: _controller.sending || _messageController.text.trim().isEmpty ? null : _send,
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : Icon(
                        _messageController.text.trim().isEmpty ? Icons.mic : Icons.send,
                        color: AppColors.white,
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

/// Plays a real voice-note attachment (`sendVoice`, confirmed live
/// 2026-07-20 - see ChatMessage.isVoiceNote's doc comment). Lazily creates
/// its own AudioPlayer only when tapped, same "don't eagerly open a
/// network stream for every bubble in the list" discipline used for the
/// feed's inline video player.
class _VoiceMessageBubble extends StatefulWidget {
  final String url;
  final bool isMe;

  const _VoiceMessageBubble({required this.url, required this.isMe});

  @override
  State<_VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<_VoiceMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (widget.url.isEmpty) return;
    if (_state == PlayerState.playing) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.url));
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? AppColors.white : AppColors.jetBlack;
    final progress = _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0.0;

    return SizedBox(
      width: 180,
      child: Row(
        children: [
          TapScale(
            onTap: _toggle,
            child: Icon(
              _state == PlayerState.playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: color.withValues(alpha: 0.25),
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _format(_duration.inMilliseconds > 0 ? _duration : _position),
                  style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
