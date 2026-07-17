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

  /// Appends only messages whose id isn't already present. The poll timer
  /// (every 4s) and a completing send() both mutate `thread.messages`
  /// independently - if a poll tick lands while a send is still
  /// in-flight (easy on a slow connection, since sendReply does a POST
  /// and a follow-up GET), the same message could get appended twice
  /// with no de-dup. This is what caused messages to visibly appear
  /// twice - fixed here rather than in each call site.
  void _appendMessages(List<ChatMessage> incoming) {
    if (thread == null || incoming.isEmpty) return;
    final existingIds = thread!.messages.map((m) => m.id).toSet();
    final deduped = incoming.where((m) => !existingIds.contains(m.id)).toList();
    if (deduped.isEmpty) return;

    // copyWith (not a manual reconstruction) so fields it doesn't touch -
    // isPinned/isMuted/otherUserOnline - survive a poll tick instead of
    // silently resetting to their defaults.
    thread = thread!.copyWith(
      lastMessagePreview: deduped.last.message,
      lastMessageDate: deduped.last.date,
      unreadCount: 0,
      messages: [...thread!.messages, ...deduped],
    );
  }

  Future<void> _pollOnce() async {
    if (_disposed || thread == null) return;
    final lastId = thread!.messages.isNotEmpty ? thread!.messages.last.id : null;
    try {
      final newOnes =
          await _repo.pollNewMessages(threadId: threadId, lastKnownMessageId: lastId);
      if (newOnes.isEmpty) return;

      _appendMessages(newOnes);
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
      _appendMessages([sent]);
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
