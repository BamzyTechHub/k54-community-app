import 'package:flutter/foundation.dart';
import '../../services/auth_service.dart';
import '../models/chat_message_model.dart';


import '../models/message_thread_model.dart';
import '../services/messaging_api_service.dart';

/// Single source of truth for messaging data.
///
/// All screens/controllers go through this repository instead of calling
/// MessagingApiService directly. That gives us:
///   - one in-memory cache of threads (avoids re-fetching the inbox from
///     three different screens on every navigation)
///   - one place that resolves "does a thread with this member already
///     exist" so New Conversation and the profile Message button can't
///     accidentally create duplicate threads
///   - one global unread-count notifier the bottom nav badge and the
///     home app-bar badge both listen to
class MessagingRepository {
  MessagingRepository._internal();
  static final MessagingRepository instance = MessagingRepository._internal();

  final MessagingApiService _api = MessagingApiService();
  final AuthService _authService = AuthService();

  String? _cachedUserId;
  List<MessageThread> _threadsCache = [];

  /// Global unread-thread count. Listen to this from any badge widget.
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Future<String> currentUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;
    final response = await _authService.getCurrentUser();
    _cachedUserId = (response.data['id'] ?? '').toString();
    return _cachedUserId!;
  }

  List<MessageThread> get cachedThreads => List.unmodifiable(_threadsCache);

  void _recalculateUnread() {
    unreadCount.value = _threadsCache.where((t) => t.isUnread).length;
  }

  /// Refreshes the inbox from the server. Always the source of truth for
  /// the unread badge.
  Future<List<MessageThread>> refreshThreads() async {
    final userId = await currentUserId();
    final response = await _api.getThreads(userId);

    // TODO(debug): temporary — remove once real /messages shape is confirmed.
    debugPrint("=== [GET /messages] response.data.runtimeType: ${response.data.runtimeType} ===");
    debugPrint("=== [GET /messages] response.data: ${response.data} ===");
    if (response.data is Map) {
      debugPrint("=== [GET /messages] top-level keys: ${(response.data as Map).keys.toList()} ===");
    }

    final List data = response.data is List
        ? response.data
        : (response.data['threads'] ?? response.data['data'] ?? []);

    _threadsCache = data
        .map((t) => MessageThread.fromJson(
              t as Map<String, dynamic>,
              currentUserId: userId,
            ))
        .toList()
      ..sort((a, b) => b.lastMessageDate.compareTo(a.lastMessageDate));

    _recalculateUnread();
    return _threadsCache;
  }

  /// Fetches a single thread with full message history. Also patches the
  /// cached inbox entry so the list preview stays in sync.
  Future<MessageThread> getThread(String threadId) async {
    final userId = await currentUserId();
    final response = await _api.getThread(threadId);

    // TODO(debug): temporary — remove once real /messages/{id} shape is confirmed.
    debugPrint("=== [GET /messages/$threadId] response.data.runtimeType: ${response.data.runtimeType} ===");
    debugPrint("=== [GET /messages/$threadId] response.data: ${response.data} ===");
    if (response.data is Map) {
      debugPrint("=== [GET /messages/$threadId] top-level keys: ${(response.data as Map).keys.toList()} ===");
    }

    final thread = MessageThread.fromJson(
      response.data as Map<String, dynamic>,
      currentUserId: userId,
    );
    _patchCache(thread);
    return thread;
  }

  /// Fetches only the messages newer than [afterMessageId], for polling.
  /// BuddyBoss doesn't offer a "since" filter on this endpoint, so this
  /// re-fetches the thread and diffs client-side rather than trusting a
  /// server-side incremental filter that doesn't exist.
  Future<List<ChatMessage>> pollNewMessages({
    required String threadId,
    required String? lastKnownMessageId,
  }) async {
    final thread = await getThread(threadId);
    if (lastKnownMessageId == null) return thread.messages;

    final lastIndex =
        thread.messages.indexWhere((m) => m.id == lastKnownMessageId);
    if (lastIndex == -1) return thread.messages; // couldn't find it, resync fully
    return thread.messages.sublist(lastIndex + 1);
  }

  Future<ChatMessage> sendReply({
    required String threadId,
    required String message,
  }) async {
    final userId = await currentUserId();
    final response = await _api.replyToThread(threadId: threadId, message: message);
    final thread = MessageThread.fromJson(
      response.data as Map<String, dynamic>,
      currentUserId: userId,
    );
    _patchCache(thread);

    if (thread.messages.isNotEmpty) return thread.messages.last;
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: userId,
      senderName: "You",
      message: message,
      date: DateTime.now(),
      isMe: true,
    );
  }

  /// Finds an existing 1:1 thread with [otherUserId] in the cache, or
  /// starts a new one. This is the ONLY path both "New Conversation" and
  /// the profile "Message" button should use, so we never create
  /// duplicate threads for the same pair of members.
  Future<MessageThread> findOrCreateThreadWith({
    required String otherUserId,
    String openingMessage = "Hi!",
  }) async {
    // Make sure the cache is warm before checking for an existing thread.
    if (_threadsCache.isEmpty) {
      await refreshThreads();
    }

    for (final thread in _threadsCache) {
      if (thread.otherUserId == otherUserId) {
        return getThread(thread.id); // fetch full message history
      }
    }

    final userId = await currentUserId();
    final response =
        await _api.startThread(recipientId: otherUserId, message: openingMessage);
    final thread = MessageThread.fromJson(
      response.data as Map<String, dynamic>,
      currentUserId: userId,
    );
    _patchCache(thread);
    return thread;
  }

  Future<void> markThreadRead(String threadId) async {
    try {
      await _api.markThread(threadId: threadId, action: "unread", value: false);
    } catch (_) {
      // Non-fatal — worst case the badge stays slightly stale until next refresh.
    }
    final index = _threadsCache.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      final t = _threadsCache[index];
      _threadsCache[index] = MessageThread(
        id: t.id,
        otherUserId: t.otherUserId,
        otherUserName: t.otherUserName,
        otherUserAvatar: t.otherUserAvatar,
        lastMessagePreview: t.lastMessagePreview,
        lastMessageDate: t.lastMessageDate,
        unreadCount: 0,
        messages: t.messages,
      );
      _recalculateUnread();
    }
  }

  Future<List<dynamic>> searchMembers(String query) async {
    final response = await _api.searchMembers(query);
    final List data = response.data is List
        ? response.data
        : (response.data['members'] ?? response.data['data'] ?? []);
    return data;
  }

  void _patchCache(MessageThread thread) {
    final index = _threadsCache.indexWhere((t) => t.id == thread.id);
    if (index != -1) {
      _threadsCache[index] = thread;
    } else {
      _threadsCache.insert(0, thread);
    }
    _recalculateUnread();
  }
}
