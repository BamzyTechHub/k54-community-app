/// A single message inside a BuddyBoss message thread.
///
/// NOTE: BuddyBoss's exact JSON key names have drifted slightly across
/// plugin versions. This parses the common shape and falls back to
/// alternates where the docs disagree. If a field comes through empty,
/// print the raw thread JSON once and adjust the key names here.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String message;
  final DateTime date;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.message,
    required this.date,
    required this.isMe,
  });

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    final sender = json['sender'] as Map<String, dynamic>?;
    final senderId = (json['sender_id'] ?? sender?['id'] ?? '').toString();

    return ChatMessage(
      id: (json['id'] ?? json['message_id'] ?? '').toString(),
      senderId: senderId,
      senderName: (sender?['name'] ?? json['sender_name'] ?? '').toString(),
      senderAvatar: (sender?['user_avatar']?['thumb'] ??
              sender?['avatar_urls']?['thumb'])
          ?.toString(),
      message: _stripHtml((json['message'] ?? json['content'] ?? '').toString()),
      date: DateTime.tryParse(
            (json['date_sent'] ?? json['date'] ?? '').toString(),
          ) ??
          DateTime.now(),
      isMe: senderId == currentUserId,
    );
  }

  static String _stripHtml(String input) =>
      input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}