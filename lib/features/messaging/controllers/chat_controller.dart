import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:k54_mobile/features/messaging/models/chat_message_model.dart';
import 'package:k54_mobile/features/messaging/models/message_thread_model.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';

class ChatController extends ChangeNotifier {
  ChatController({required this.threadId, MessageThread? initialThread})
      : thread = initialThread;

  final String threadId;
  final MessagingRepository _repo = MessagingRepository.instance;

  MessageThread? thread;
  bool loading = true;
  bool sending = false;
  String? error;

  Timer? _pollTimer;
  bool _disposed = false;
  static const _pollInterval = Duration(seconds: 4);

  List<ChatMessage> get messages => thread?.messages ?? const [];

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      thread = await _repo.getThread(threadId);
      await _repo.markThreadRead(threadId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      // The awaits above can outlive this controller if the chat page was
      // popped mid-fetch — dispose() cancels the poll timer but can't
      // cancel an in-flight Future, so this can still run after dispose().
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  /// Call once after the first successful load. Polls for new messages
  /// only — it never re-renders the whole message list, it just appends.
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    if (_disposed || thread == null) return;
    final lastId = thread!.messages.isNotEmpty ? thread!.messages.last.id : null;
    try {
      final newOnes =
          await _repo.pollNewMessages(threadId: threadId, lastKnownMessageId: lastId);
      if (newOnes.isEmpty) return;

      thread = MessageThread(
        id: thread!.id,
        otherUserId: thread!.otherUserId,
        otherUserName: thread!.otherUserName,
        otherUserAvatar: thread!.otherUserAvatar,
        lastMessagePreview: newOnes.last.message,
        lastMessageDate: newOnes.last.date,
        unreadCount: 0,
        messages: [...thread!.messages, ...newOnes],
      );
      if (!_disposed) {
        notifyListeners();
      }
    } catch (_) {
      // Silent failure on a background poll tick — don't spam the user
      // with errors for a transient network hiccup. The next tick retries.
    }
  }

  Future<bool> send(String text) async {
    if (text.trim().isEmpty || sending) return false;
    sending = true;
    notifyListeners();
    try {
      final sent = await _repo.sendReply(threadId: threadId, message: text.trim());
      thread = MessageThread(
        id: thread!.id,
        otherUserId: thread!.otherUserId,
        otherUserName: thread!.otherUserName,
        otherUserAvatar: thread!.otherUserAvatar,
        lastMessagePreview: sent.message,
        lastMessageDate: sent.date,
        unreadCount: 0,
        messages: [...thread!.messages, sent],
      );
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      sending = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }
}
