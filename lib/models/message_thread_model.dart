import 'chat_model.dart';

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

  factory MessageThread.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    // 'recipients' includes every participant; find the one who isn't me
    // for a 1:1 thread. Group threads aren't handled here yet.
    final recipients = (json['recipients'] as List?) ?? [];
    Map<String, dynamic>? other;
    for (final r in recipients) {
      final rMap = r as Map<String, dynamic>;
      final rId = (rMap['id'] ?? rMap['user_id'] ?? '').toString();
      if (rId != currentUserId) {
        other = rMap;
        break;
      }
    }
    other ??= recipients.isNotEmpty ? recipients.first as Map<String, dynamic> : null;

    final messagesJson = (json['messages'] as List?) ?? [];
    final messages = messagesJson
        .map((m) => ChatMessage.fromJson(
              m as Map<String, dynamic>,
              currentUserId: currentUserId,
            ))
        .toList();

    return MessageThread(
      id: (json['id'] ?? json['thread_id'] ?? '').toString(),
      otherUserId: (other?['id'] ?? other?['user_id'] ?? '').toString(),
      otherUserName: (other?['name'] ?? 'Unknown').toString(),
      otherUserAvatar:
          (other?['user_avatar']?['thumb'] ?? other?['avatar_urls']?['thumb'])
              ?.toString(),
      lastMessagePreview: _stripHtml(
        (json['excerpt'] ?? json['message'] ?? '').toString(),
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

String _stripHtml(String input) =>
    input.replaceAll(RegExp(r'<[^>]*>'), '').trim();