/// A single message inside a BuddyBoss message thread.
///
/// NOTE: BuddyBoss's exact JSON key names have drifted slightly across
/// plugin versions. This parses the common shape and falls back to
/// alternates where the docs disagree. If a field comes through empty,
/// capture the raw thread JSON once (see MessagingService docs) and
/// adjust the key names here to match your install exactly.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String message;
  final DateTime date;
  final bool isMe;

  /// Present only if this message carries an uploaded image
  /// (BuddyBoss Media component, bp_media_ids).
  final String? imageUrl;
  final String? imageThumbUrl;

  /// Present only if this message carries an uploaded file
  /// (BuddyBoss Document component, bp_document_ids).
  final String? documentUrl;
  final String? documentName;

  bool get hasAttachment =>
      imageUrl != null || documentUrl != null;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.message,
    required this.date,
    required this.isMe,
    this.imageUrl,
    this.imageThumbUrl,
    this.documentUrl,
    this.documentName,
  });

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    final sender = json['sender'] as Map<String, dynamic>?;
    final senderId = (json['sender_id'] ?? sender?['id'] ?? '').toString();

    // bp_media_ids field shape (per BuddyBoss docs):
    // [{ "id": .., "full": "https://...", "thumb": "https://..." }, ...]
    final mediaList = json['bp_media_ids'] as List?;
    final firstMedia = (mediaList != null && mediaList.isNotEmpty)
        ? mediaList.first as Map<String, dynamic>
        : null;

    // bp_document_ids field shape is not officially documented in the
    // public reference the way media is; adapt this block once you've
    // captured a real response with a document attached.
    final documentList = json['bp_document_ids'] as List?;
    final firstDocument = (documentList != null && documentList.isNotEmpty)
        ? documentList.first as Map<String, dynamic>
        : null;

    return ChatMessage(
      id: (json['id'] ?? json['message_id'] ?? '').toString(),
      senderId: senderId,
      senderName: (sender?['name'] ?? json['sender_name'] ?? '').toString(),
      senderAvatar: (sender?['user_avatar']?['thumb'] ??
              sender?['avatar_urls']?['thumb'])
          ?.toString(),
      message: stripHtml(extractRendered(json['message'] ?? json['content'])),
      date: DateTime.tryParse(
            (json['date_sent'] ?? json['date'] ?? '').toString(),
          ) ??
          DateTime.now(),
      isMe: senderId == currentUserId,
      imageUrl: firstMedia?['full']?.toString(),
      imageThumbUrl: firstMedia?['thumb']?.toString(),
      documentUrl: firstDocument?['url']?.toString(),
      documentName: firstDocument?['name']?.toString(),
    );
  }
}

String stripHtml(String input) =>
    input.replaceAll(RegExp(r'<[^>]*>'), '').trim();

/// WP REST API commonly returns "content-like" fields (subject, excerpt,
/// message, content) as `{ rendered: "...", raw: "..." }` rather than a
/// plain string. Confirmed for `excerpt` against the live k54global.com
/// response (2026-07-06) — apply the same extraction wherever this shape
/// might appear instead of stringifying the whole object.
String extractRendered(dynamic value) {
  if (value is Map) {
    return (value['rendered'] ?? '').toString();
  }
  return (value ?? '').toString();
}
