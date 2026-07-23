import 'package:k54_mobile/features/messaging/models/chat_message_model.dart';

/// A Better Messages thread (what shows up as one row on the inbox list) -
/// the website's real messaging system, see
/// docs/api-audit/messaging-better-messages.md.
class MessageThread {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  // Real presence data - Better Messages' users[] carries
  // status: {slug, icon, label} (confirmed live 2026-07-07, see
  // docs/api-audit/messaging-better-messages.md), not a guessed/always-on
  // dot.
  final bool otherUserOnline;
  final String lastMessagePreview;
  final DateTime lastMessageDate;
  final int unreadCount;
  final List<ChatMessage> messages;
  final bool isPinned;
  final bool isMuted;
  final int participantCount;

  MessageThread({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.otherUserOnline = false,
    required this.lastMessagePreview,
    required this.lastMessageDate,
    required this.unreadCount,
    this.messages = const [],
    this.isPinned = false,
    this.isMuted = false,
    this.participantCount = 2,
  });

  /// True for a group's own multi-participant thread (e.g. the one behind
  /// a group's real "Messages" tab - confirmed live 2026-07-22, `type:
  /// "group"` on the thread object) rather than a 1-on-1 conversation.
  /// `otherUserName`/`otherUserAvatar` are repurposed to hold the group's
  /// own `title`/`image` in this case (see fromBetterMessages) rather
  /// than a single other person's - deliberately, so ChatPage's existing
  /// header rendering needs no changes to display either kind correctly.
  bool get isGroupThread => participantCount > 2;

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
      otherUserOnline: otherUserOnline,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageDate: lastMessageDate ?? this.lastMessageDate,
      unreadCount: unreadCount ?? this.unreadCount,
      messages: messages ?? this.messages,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      participantCount: participantCount,
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
    final isGroup = json['type'] == 'group';

    String otherUserId = '';
    Map<String, dynamic>? otherUser;
    if (!isGroup) {
      String? found;
      for (final p in participants) {
        final pid = p.toString();
        if (pid != currentUserId) {
          found = pid;
          break;
        }
      }
      otherUserId = found ?? (participants.isNotEmpty ? participants.first.toString() : '');
      otherUser = usersById[otherUserId];
    }

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
      // Group threads: real group name/avatar from the thread itself
      // (confirmed live 2026-07-22 - `title`/`subject` + `image` on a
      // real `type: "group"` thread), not one arbitrarily-picked
      // participant.
      otherUserName: isGroup
          ? (json['title'] ?? json['subject'] ?? 'Group').toString()
          : (otherUser?['name'] ?? 'Unknown').toString(),
      otherUserAvatar: isGroup ? json['image']?.toString() : otherUser?['avatar']?.toString(),
      otherUserOnline: !isGroup && (otherUser?['status'] is Map) && (otherUser!['status']['slug'] == 'online'),
      participantCount: int.tryParse('${json['participantsCount'] ?? participants.length}') ?? participants.length,
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
