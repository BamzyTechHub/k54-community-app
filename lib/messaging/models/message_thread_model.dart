import 'chat_message_model.dart';

/// A BuddyBoss message thread (what shows up as one row on the inbox list).
class MessageThread {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessagePreview;
  final DateTime lastMessageDate;
  final int unreadCount;
  final List<ChatMessage> messages;

  MessageThread({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.lastMessagePreview,
    required this.lastMessageDate,
    required this.unreadCount,
    this.messages = const [],
  });

  bool get isUnread => unreadCount > 0;

  MessageThread copyWith({
    int? unreadCount,
    List<ChatMessage>? messages,
    String? lastMessagePreview,
    DateTime? lastMessageDate,
  }) {
    return MessageThread(
      id: id,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserAvatar: otherUserAvatar,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageDate: lastMessageDate ?? this.lastMessageDate,
      unreadCount: unreadCount ?? this.unreadCount,
      messages: messages ?? this.messages,
    );
  }

  factory MessageThread.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    // Confirmed against the live k54global.com response (2026-07-06):
    // BuddyBoss returns 'recipients' as a JSON object keyed by user ID,
    // e.g. {"5": {...}, "12": {...}} — not a JSON array. This matches
    // BuddyPress core's internal BP_Messages_Thread::$recipients, which
    // is PHP-associative by user ID. An empty PHP array still encodes
    // as `[]`, so a List is tolerated here too (as "no recipients"),
    // but a populated recipients list is only ever a Map on this site.
    final recipientsRaw = json['recipients'];
    final recipients = recipientsRaw is Map
        ? recipientsRaw.values
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList()
        : <Map<String, dynamic>>[];

    // 'recipients' includes every participant; find the one who isn't me
    // for a 1:1 thread. Group threads aren't handled here yet.
    //
    // Each recipient object carries two different IDs — confirmed from the
    // live payload, e.g. {id: 8, user_id: 5, ...} where the outer Map key
    // ("5") matches user_id, not id. `id` is the bp_messages_recipients
    // row's own ID; `user_id` is the actual WP user ID, which is what must
    // be compared against currentUserId. Using `id` here always failed to
    // match, so the loop fell through to "whichever recipient came first"
    // every time — which was consistently the current user.
    Map<String, dynamic>? other;
    for (final r in recipients) {
      final rId = (r['user_id'] ?? '').toString();
      if (rId != currentUserId) {
        other = r;
        break;
      }
    }
    other ??= recipients.isNotEmpty ? recipients.first : null;

    final messagesJson = (json['messages'] as List?) ?? [];
    final messages = messagesJson
        .map((m) => ChatMessage.fromJson(
              m as Map<String, dynamic>,
              currentUserId: currentUserId,
            ))
        .toList();

    return MessageThread(
      id: (json['id'] ?? json['thread_id'] ?? '').toString(),
      // Same user_id-vs-id distinction as above: user_id is the real WP
      // user ID, id is the recipient row's own ID.
      otherUserId: (other?['user_id'] ?? '').toString(),
      otherUserName: (other?['name'] ?? 'Unknown').toString(),
      otherUserAvatar:
          (other?['user_avatar']?['thumb'] ?? other?['avatar_urls']?['thumb'])
              ?.toString(),
      lastMessagePreview: stripHtml(
        extractRendered(json['excerpt'] ?? json['message']),
      ),
      lastMessageDate:
          DateTime.tryParse((json['date'] ?? json['last_message_date'] ?? '')
                  .toString()) ??
              DateTime.now(),
      unreadCount: json['unread_count'] is bool
          ? (json['unread_count'] == true ? 1 : 0)
          : int.tryParse('${json['unread_count'] ?? 0}') ?? 0,
      messages: messages,
    );
  }
}
