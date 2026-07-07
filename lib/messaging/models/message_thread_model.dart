import 'chat_message_model.dart';

/// A Better Messages thread (what shows up as one row on the inbox list) -
/// the website's real messaging system, see
/// docs/api-audit/messaging-better-messages.md.
class MessageThread {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessagePreview;
  final DateTime lastMessageDate;
  final int unreadCount;
  final List<ChatMessage> messages;
  final bool isPinned;
  final bool isMuted;

  MessageThread({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.lastMessagePreview,
    required this.lastMessageDate,
    required this.unreadCount,
    this.messages = const [],
    this.isPinned = false,
    this.isMuted = false,
  });

  bool get isUnread => unreadCount > 0;

  MessageThread copyWith({
    int? unreadCount,
    List<ChatMessage>? messages,
    String? lastMessagePreview,
    DateTime? lastMessageDate,
    bool? isPinned,
    bool? isMuted,
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
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  /// Builds a thread from Better Messages' response envelope, which
  /// returns threads/users/messages as three separate top-level arrays
  /// (confirmed shape, `thread/{id}` and `threads` responses) rather than
  /// nesting them - [users] and [threadMessages] must already be filtered/
  /// looked up by the caller for this specific thread.
  factory MessageThread.fromBetterMessages(
    Map<String, dynamic> json, {
    required String currentUserId,
    required Map<String, Map<String, dynamic>> usersById,
    required List<Map<String, dynamic>> threadMessages,
  }) {
    final participants = (json['participants'] as List?) ?? [];
    String? otherUserId;
    for (final p in participants) {
      final pid = p.toString();
      if (pid != currentUserId) {
        otherUserId = pid;
        break;
      }
    }
    otherUserId ??= participants.isNotEmpty ? participants.first.toString() : '';

    final otherUser = usersById[otherUserId];

    final sortedMessages = [...threadMessages]
      ..sort((a, b) => (a['created_at'] as num? ?? 0).compareTo(b['created_at'] as num? ?? 0));

    final messages = sortedMessages
        .map((m) => ChatMessage.fromBetterMessages(
              m,
              currentUserId: currentUserId,
              senderUser: usersById[(m['sender_id'] ?? '').toString()],
            ))
        .toList();

    final lastMessage = messages.isNotEmpty ? messages.last : null;

    return MessageThread(
      id: (json['thread_id'] ?? json['id'] ?? '').toString(),
      otherUserId: otherUserId,
      otherUserName: (otherUser?['name'] ?? 'Unknown').toString(),
      otherUserAvatar: otherUser?['avatar']?.toString(),
      lastMessagePreview: lastMessage?.message ?? '',
      lastMessageDate: lastMessage?.date ??
          parseBetterMessagesTimestamp(json['lastTime']),
      unreadCount: json['unread'] is bool
          ? (json['unread'] == true ? 1 : 0)
          : int.tryParse('${json['unread'] ?? 0}') ?? 0,
      messages: messages,
      isPinned: json['isPinned'] == 1 || json['isPinned'] == true,
      isMuted: json['isMuted'] == true,
    );
  }
}
