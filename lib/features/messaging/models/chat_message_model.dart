/// A single message inside a Better Messages thread (the website's real
/// messaging system - see docs/api-audit/messaging-better-messages.md).
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String message;
  final DateTime date;
  final bool isMe;

  /// Client-generated id used for optimistic sends, echoed back by the
  /// server on the reconciled message (confirmed live: the same temp_id
  /// reappears on the real message once persisted).
  final String? tempId;

  /// Emoji reactions on this message. Always empty in every capture so
  /// far - the field is confirmed real (`meta.reactions: []` on every
  /// message) but no populated example, and no confirmed endpoint to add
  /// one, has been captured yet.
  final List<String> reactions;

  /// Per-message favorite/star, separate from any whole-thread star.
  final bool favorited;

  /// Whether this is a voice note (sent via `sendVoice`, confirmed live
  /// 2026-07-20 - see docs/api-audit/messaging-better-messages.md). The
  /// raw message body is an HTML `<div class="bpbm-voice-message"
  /// data-message="{audioUrl}">` wrapper with no real text, so it can't be
  /// displayed via the normal stripHtml path - [voiceUrl] is the actual
  /// playable audio URL (read from meta.files[0].url, a cleaner parse
  /// target than the HTML attribute).
  final bool isVoiceNote;
  final String voiceUrl;

  /// Whether this specific message is pinned (`thread/{id}/pinMessage`,
  /// confirmed live 2026-07-20). Not present on the raw API response -
  /// this is set/cleared client-side by ChatController after a successful
  /// pin/unpin call, same optimistic-then-reconcile pattern used elsewhere.
  final bool isPinned;

  /// Attached files (Better Messages' own dedicated media path, confirmed
  /// distinct from BuddyBoss's bp_media_ids). A files-only message uses the
  /// literal body "<!-- BM-ONLY-FILES -->" as a sentinel - callers should
  /// treat that string as "no text" rather than displaying it.
  final List<ChatAttachment> files;

  bool get hasAttachment => files.isNotEmpty;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.message,
    required this.date,
    required this.isMe,
    this.tempId,
    this.reactions = const [],
    this.favorited = false,
    this.files = const [],
    this.isVoiceNote = false,
    this.voiceUrl = "",
    this.isPinned = false,
  });

  ChatMessage copyWith({bool? isPinned}) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      message: message,
      date: date,
      isMe: isMe,
      tempId: tempId,
      reactions: reactions,
      favorited: favorited,
      files: files,
      isVoiceNote: isVoiceNote,
      voiceUrl: voiceUrl,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  factory ChatMessage.fromBetterMessages(
    Map<String, dynamic> json, {
    required String currentUserId,
    Map<String, dynamic>? senderUser,
  }) {
    final senderId = (json['sender_id'] ?? '').toString();
    final meta = json['meta'] is Map ? json['meta'] as Map : const {};

    final filesRaw = meta['files'] as List?;
    final files = (filesRaw ?? [])
        .whereType<Map>()
        .map((f) => ChatAttachment.fromJson(Map<String, dynamic>.from(f)))
        .toList();

    final rawMessage = extractRendered(json['message']);
    final isVoiceNote = rawMessage.contains('bpbm-voice-message');
    final voiceUrl = isVoiceNote
        ? (files.isNotEmpty ? files.first.url : '')
        : '';

    var body = stripHtml(rawMessage);
    if (body == "<!-- BM-ONLY-FILES -->" || isVoiceNote) body = "";

    return ChatMessage(
      id: (json['message_id'] ?? json['temp_id'] ?? '').toString(),
      senderId: senderId,
      senderName: (senderUser?['name'] ?? '').toString(),
      senderAvatar: senderUser?['avatar']?.toString(),
      message: body,
      date: parseBetterMessagesTimestamp(json['created_at']),
      isMe: senderId == currentUserId,
      tempId: json['temp_id']?.toString(),
      reactions: (meta['reactions'] as List?)?.map((r) => r.toString()).toList() ?? const [],
      favorited: json['favorited'] == 1 || json['favorited'] == true,
      files: files,
      isVoiceNote: isVoiceNote,
      voiceUrl: voiceUrl,
    );
  }
}

class ChatAttachment {
  final String id;
  final String url;
  final String thumbUrl;
  final String name;
  final String mimeType;

  ChatAttachment({
    required this.id,
    required this.url,
    required this.thumbUrl,
    required this.name,
    required this.mimeType,
  });

  bool get isImage => mimeType.startsWith("image/");

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      id: (json['id'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      thumbUrl: (json['thumb'] ?? json['url'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      mimeType: (json['mimeType'] ?? '').toString(),
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

/// Better Messages' `created_at`/`lastTime` values are one digit longer
/// than a plausible unix-ms epoch for the same moment (e.g. a captured
/// `17834230662434` vs. an expected ~13-digit `1783423066243`) - the exact
/// scale isn't confirmed by any capture (docs/api-audit explicitly flags
/// this as "not reverse-engineered"). This divides by 10 and sanity-checks
/// the result lands in a plausible calendar year rather than trusting the
/// heuristic blindly; falls back to now() if it doesn't check out.
DateTime parseBetterMessagesTimestamp(dynamic raw) {
  final n = raw is num ? raw : num.tryParse('$raw');
  if (n == null) return DateTime.now();
  final candidateMs = (n / 10).round();
  final asDate = DateTime.fromMillisecondsSinceEpoch(candidateMs);
  if (asDate.year >= 2020 && asDate.year <= 2035) return asDate;
  return DateTime.now();
}
