import 'package:flutter/foundation.dart';
import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/features/messaging/models/chat_message_model.dart';

import 'package:k54_mobile/features/messaging/models/message_thread_model.dart';
import 'package:k54_mobile/features/messaging/services/better_messages_api_service.dart';

/// Single source of truth for messaging data, backed by Better Messages -
/// the same system the website's own `/messenger/` UI uses (see
/// docs/api-audit/messaging-better-messages.md). Previously called
/// BuddyBoss's own native messaging REST API, which is a separate,
/// disconnected message store the website doesn't use - that meant
/// messages sent from this app could never appear on the website and vice
/// versa. Migrated so both platforms are finally looking at the same data.
///
/// All screens/controllers go through this repository instead of calling
/// BetterMessagesApiService directly. That gives us:
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

  final BetterMessagesApiService _api = BetterMessagesApiService();
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

  /// threads/users/messages come back as three separate top-level arrays
  /// (confirmed shape) rather than nested per-thread - this joins them
  /// client-side into hydrated MessageThread objects.
  List<MessageThread> _hydrate(
    Map<String, dynamic> envelope,
    String currentUserId,
  ) {
    final threadsRaw = (envelope['threads'] as List?) ?? [];
    final usersRaw = (envelope['users'] as List?) ?? [];
    final messagesRaw = (envelope['messages'] as List?) ?? [];

    final usersById = <String, Map<String, dynamic>>{};
    for (final u in usersRaw.whereType<Map>()) {
      final map = Map<String, dynamic>.from(u);
      final id = (map['user_id'] ?? map['id'] ?? '').toString();
      if (id.isNotEmpty) usersById[id] = map;
    }

    final messagesByThread = <String, List<Map<String, dynamic>>>{};
    for (final m in messagesRaw.whereType<Map>()) {
      final map = Map<String, dynamic>.from(m);
      final threadId = (map['thread_id'] ?? '').toString();
      messagesByThread.putIfAbsent(threadId, () => []).add(map);
    }

    return threadsRaw.whereType<Map>().map((t) {
      final map = Map<String, dynamic>.from(t);
      final threadId = (map['thread_id'] ?? map['id'] ?? '').toString();
      return MessageThread.fromBetterMessages(
        map,
        currentUserId: currentUserId,
        usersById: usersById,
        threadMessages: messagesByThread[threadId] ?? const [],
      );
    }).toList();
  }

  /// Refreshes the inbox from the server. Always the source of truth for
  /// the unread badge.
  Future<List<MessageThread>> refreshThreads() async {
    final userId = await currentUserId();
    final response = await _api.getThreads();
    final envelope = response.data as Map<String, dynamic>;

    _threadsCache = _dedupeByContact(_hydrate(envelope, userId))
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.lastMessageDate.compareTo(a.lastMessageDate);
      });

    _recalculateUnread();
    return _threadsCache;
  }

  /// Better Messages can genuinely have more than one thread with the same
  /// person (e.g. one started from the site's own UI, another from this
  /// app's "Message" button before this dedup existed) - real server data,
  /// not a parsing bug. Showing every one of them as a separate inbox row
  /// is confusing (the same contact appearing 2-3 times, most with no
  /// messages at all), so this keeps exactly one row per other-user:
  /// whichever thread actually has messages, tie-broken by the most
  /// recently active one. Threads with a different `otherUserId` (or
  /// group threads, where multiple participants exist) are left alone.
  List<MessageThread> _dedupeByContact(List<MessageThread> threads) {
    final byContact = <String, MessageThread>{};
    for (final thread in threads) {
      final key = thread.otherUserId;
      final existing = byContact[key];
      if (existing == null) {
        byContact[key] = thread;
        continue;
      }
      final existingHasMessages = existing.messages.isNotEmpty || existing.lastMessagePreview.isNotEmpty;
      final thisHasMessages = thread.messages.isNotEmpty || thread.lastMessagePreview.isNotEmpty;
      if (thisHasMessages && !existingHasMessages) {
        byContact[key] = thread;
      } else if (thisHasMessages == existingHasMessages &&
          thread.lastMessageDate.isAfter(existing.lastMessageDate)) {
        byContact[key] = thread;
      }
    }
    return byContact.values.toList();
  }

  /// Fetches a single thread with full message history. Also patches the
  /// cached inbox entry so the list preview stays in sync.
  Future<MessageThread> getThread(String threadId) async {
    final userId = await currentUserId();
    final response = await _api.getThread(threadId);
    final envelope = response.data as Map<String, dynamic>;

    final hydrated = _hydrate(envelope, userId);
    final thread = hydrated.firstWhere(
      (t) => t.id == threadId,
      orElse: () => hydrated.isNotEmpty
          ? hydrated.first
          : throw StateError("Thread $threadId not found in response"),
    );
    _patchCache(thread);
    return thread;
  }

  /// Fetches only the messages newer than [afterMessageId], for polling.
  /// No confirmed "since" filter exists for a single thread, so this
  /// re-fetches the thread and diffs client-side, same approach used
  /// against the old BuddyBoss API for the same reason.
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
    final tempId = "tmp_${threadId}_${DateTime.now().millisecondsSinceEpoch}";

    // The send response body isn't a confirmed shape (see
    // BetterMessagesApiService.sendMessage's doc comment) - re-fetch the
    // thread afterward instead of trusting anything back from this call.
    await _api.sendMessage(
      threadId: threadId,
      message: message,
      tempId: tempId,
      tempTime: DateTime.now().millisecondsSinceEpoch,
    );

    final thread = await getThread(threadId);
    if (thread.messages.isNotEmpty) return thread.messages.last;

    return ChatMessage(
      id: tempId,
      senderId: userId,
      senderName: "You",
      message: message,
      date: DateTime.now(),
      isMe: true,
    );
  }

  /// Finds an existing 1:1 thread with [otherUserId] in the cache and
  /// opens it, or creates a brand-new one via `thread/new` (confirmed
  /// live 2026-07-14, HAR capture - see BetterMessagesApiService's doc
  /// comment) when none exists yet.
  Future<MessageThread> findOrCreateThreadWith({
    required String otherUserId,
    String openingMessage = "Hi!",
  }) async {
    if (_threadsCache.isEmpty) {
      await refreshThreads();
    }

    for (final thread in _threadsCache) {
      if (thread.otherUserId == otherUserId) {
        return getThread(thread.id); // fetch full message history
      }
    }

    await _api.startNewConversation(recipients: [otherUserId], message: openingMessage);
    // The create response body isn't trustworthy (empty in the capture) -
    // re-fetch the inbox so the new thread comes back through the same
    // parsing path as everything else, then locate it by recipient.
    await refreshThreads();
    for (final thread in _threadsCache) {
      if (thread.otherUserId == otherUserId) {
        return getThread(thread.id);
      }
    }

    throw StateError("Couldn't start the conversation - it didn't appear in the inbox after creating it.");
  }

  /// No confirmed REST endpoint marks a single thread read (the website
  /// only demonstrated this over its WebSocket's `threadOpen` event,
  /// deferred to Stage C) - this only updates the local cache/badge
  /// optimistically. Worst case the badge is stale until the next
  /// refreshThreads() call, the same acceptable-risk bar used elsewhere in
  /// this app for unconfirmed write endpoints.
  Future<void> markThreadRead(String threadId) async {
    final index = _threadsCache.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      _threadsCache[index] = _threadsCache[index].copyWith(unreadCount: 0);
      _recalculateUnread();
    }
  }

  Future<void> pinThread(String threadId) async {
    await _api.pinThread(threadId);
    final index = _threadsCache.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      _threadsCache[index] = _threadsCache[index].copyWith(isPinned: true);
    }
  }

  Future<void> unpinThread(String threadId) async {
    await _api.unpinThread(threadId);
    final index = _threadsCache.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      _threadsCache[index] = _threadsCache[index].copyWith(isPinned: false);
    }
  }

  Future<void> eraseThread(String threadId) async {
    await _api.eraseThread(threadId);
    _threadsCache.removeWhere((t) => t.id == threadId);
    _recalculateUnread();
  }

  Future<void> blockUser(String userId) => _api.blockUser(userId);

  Future<void> unblockUser(String userId) => _api.unblockUser(userId);

  Future<List<dynamic>> searchMembers(String query) async {
    final response = await _api.getFriends();
    final List all = response.data is List ? response.data : [];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.whereType<Map>().where((m) {
      final name = (m['name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
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
