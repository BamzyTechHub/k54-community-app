import 'dart:io';
import 'package:dio/dio.dart';
import 'package:k54_mobile/core/services/api_service.dart';

/// Thin wrapper around the Better Messages plugin's own REST API
/// (`/wp-json/better-messages/v1/*`) — the system the website's real
/// `/messenger/` UI actually uses, confirmed via HAR capture (see
/// docs/api-audit/messaging-better-messages.md). JWT-bearer-only auth was
/// directly tested and confirmed working for this namespace (2026-07-07,
/// curl, both GET and POST) - no cookie/nonce needed, so this reuses the
/// same ApiService/Dio instance as every other service in the app.
///
/// Only endpoints with a captured, confirmed request/response shape are
/// implemented here. A single-thread mark-read call has NO confirmed
/// shape - the website only demonstrated read-marking over its WebSocket
/// (`threadOpen` event, out of scope until Stage C) - so it's not
/// implemented here; callers must not invent a payload for it.
///
/// `startNewConversation` (thread/new), `reactToMessage`
/// (reactions/save), `blockUser`/`unblockUser` were captured live
/// 2026-07-14 (HAR, real browser session) - same `/better-messages/v1/`
/// namespace and JWT auth as everything else here, so they carry the
/// same confidence level. Their response bodies were empty in the
/// capture (fire-and-forget from the site's own UI), so callers should
/// re-fetch (threads/thread) afterward rather than trust anything back,
/// same discipline as sendMessage below.
class BetterMessagesApiService {
  final ApiService _api = ApiService.instance;

  /// Polls for anything new since [lastUpdate] (server-time, same scale as
  /// the response envelope's own `currentTime`/`serverTime` fields - not a
  /// standard epoch, see MessageThread's timestamp parsing note).
  ///
  /// [threadIds]/[visibleThreads] sent as ints, not strings - confirmed
  /// from a real captured browser request (HAR 2026-07-21:
  /// `{"threadIds":[16,23,28,...]}`), the previous string-encoded version
  /// was an unconfirmed guess.
  Future<Response> checkNew({
    required int lastUpdate,
    required List<String> threadIds,
    List<String> visibleThreads = const [],
  }) {
    return _api.post("/better-messages/v1/checkNew", {
      "lastUpdate": lastUpdate,
      "visibleThreads": visibleThreads.map((id) => int.tryParse(id) ?? id).toList(),
      "threadIds": threadIds.map((id) => int.tryParse(id) ?? id).toList(),
    });
  }

  /// Fetches the thread list. Confirmed "exclude already-known IDs"
  /// pagination pattern rather than page/offset.
  Future<Response> getThreads({List<String> exclude = const []}) {
    return _api.post("/better-messages/v1/threads", {"exclude": exclude});
  }

  Future<Response> getThread(String threadId) {
    return _api.post("/better-messages/v1/thread/$threadId", {});
  }

  /// Sends a message to an EXISTING thread only. The send response body
  /// itself was never captured live (confirmed empty in the one capture
  /// available) - callers should re-fetch the thread afterward rather than
  /// trust anything back from this call, same no-response-trust discipline
  /// used elsewhere in this codebase for unconfirmed response shapes.
  Future<Response> sendMessage({
    required String threadId,
    required String message,
    required String tempId,
    required int tempTime,
  }) {
    return _api.post("/better-messages/v1/thread/$threadId/send", {
      "message": message,
      "temp_id": tempId,
      "temp_time": tempTime,
      "meta": {},
    });
  }

  /// Sends a generic file/image attachment (as opposed to a voice note -
  /// see sendVoice) to a message. Confirmed live 2026-07-20 via a
  /// disposable-message test (sent, verified real `meta.files` came back
  /// with the real image, then deleted): the body needs BOTH the
  /// `<!-- BM-ONLY-FILES -->` sentinel as `message` (same one confirmed
  /// present on real file-only messages in the schema doc, see
  /// docs/api-audit/messaging-better-messages.md) AND `files: [id]` -
  /// tried `attachment_id`/`attachments`/`attachment_ids` first, none of
  /// those actually attached anything despite not erroring, only `files`
  /// did. Same two-step flow as sendVoice: [uploadAttachment] first to
  /// get the id.
  Future<Response> sendFile({
    required String threadId,
    required int attachmentId,
    required String tempId,
    required int tempTime,
  }) {
    return _api.post("/better-messages/v1/thread/$threadId/send", {
      "message": "<!-- BM-ONLY-FILES -->",
      "files": [attachmentId],
      "temp_id": tempId,
      "temp_time": tempTime,
    });
  }

  /// Confirmed response: bare boolean `true`.
  Future<Response> pinThread(String threadId) {
    return _api.post("/better-messages/v1/thread/$threadId/makePinned", {});
  }

  /// Response not directly captured; inferred to mirror pinThread's bare
  /// `true` since it's the obvious counterpart action on the same resource.
  Future<Response> unpinThread(String threadId) {
    return _api.post("/better-messages/v1/thread/$threadId/unmakePinned", {});
  }

  /// Confirmed response: bare boolean `true`.
  Future<Response> eraseThread(String threadId) {
    return _api.post("/better-messages/v1/thread/$threadId/erase", {});
  }

  Future<Response> getFriends() {
    return _api.get("/better-messages/v1/getFriends");
  }

  /// Maps this account's groups to their own group-wide message thread -
  /// confirmed live 2026-07-22: `[{group_id, name, messages, thread_id,
  /// image, url}]`. Every group with "Group Messages" enabled (a real
  /// per-group Manage > Settings toggle - all members auto-join this one
  /// thread) has a `thread_id` here; this is how a group's own "Messages"
  /// tab is real-mapped to an actual Better Messages thread rather than a
  /// 1-on-1 conversation.
  Future<Response> getGroups() {
    return _api.get("/better-messages/v1/getGroups");
  }

  /// Search/list users to start a new conversation with. No query
  /// parameter was present in the captured call (the site's UI showed
  /// default suggestions without a typed search yet) - if server-side
  /// text search turns out to be needed, that's a separate capture.
  Future<Response> userSuggestions() {
    return _api.get("/better-messages/v1/userSuggestions");
  }

  /// Creates a brand-new thread (or the site's own real behavior when no
  /// thread with these recipients exists yet - `thread/suggest`, which
  /// would dedup server-side, was captured too but its response shape
  /// wasn't, so this always goes straight to thread/new; local-cache
  /// dedup already happens one level up in MessagingRepository).
  Future<Response> startNewConversation({
    required List<String> recipients,
    required String message,
    String subject = "",
  }) {
    return _api.post("/better-messages/v1/thread/new", {
      "recipients": recipients,
      "message": message,
      "subject": subject,
      "meta": {},
    });
  }

  Future<Response> reactToMessage({required String messageId, required String emoji}) {
    return _api.post("/better-messages/v1/reactions/save", {
      "message_id": messageId,
      "emoji": emoji,
    });
  }

  /// `user_id` sent as an int, not a string - confirmed from a real
  /// captured browser request (`{"user_id":123}`, HAR 2026-07-21) - the
  /// previous string-encoded version was an unconfirmed guess.
  Future<Response> blockUser(String userId) {
    return _api.post("/better-messages/v1/blockUser", {"user_id": int.tryParse(userId) ?? userId});
  }

  Future<Response> unblockUser(String userId) {
    return _api.post("/better-messages/v1/unblockUser", {"user_id": int.tryParse(userId) ?? userId});
  }

  /// Confirmed live 2026-07-20 via a disposable-message test (see
  /// docs/api-audit/messaging-better-messages.md): body key MUST be
  /// camelCase `messageId` - `message_id`/snake_case returns a misleading
  /// `403 rest_forbidden "Message not found"` instead of a validation error.
  Future<Response> pinMessage({required String threadId, required String messageId}) {
    return _api.post("/better-messages/v1/thread/$threadId/pinMessage", {
      "messageId": int.tryParse(messageId) ?? messageId,
    });
  }

  Future<Response> unpinMessage({required String threadId, required String messageId}) {
    return _api.post("/better-messages/v1/thread/$threadId/unpinMessage", {
      "messageId": int.tryParse(messageId) ?? messageId,
    });
  }

  /// Confirmed live 2026-07-20: body key MUST be camelCase plural
  /// `messageIds` - singular/snake_case variants either 403 or crash the
  /// server with an uncaught PHP TypeError (see doc above), never send
  /// those shapes.
  Future<Response> deleteMessages({required String threadId, required List<String> messageIds}) {
    return _api.post("/better-messages/v1/thread/$threadId/deleteMessages", {
      "messageIds": messageIds.map((id) => int.tryParse(id) ?? id).toList(),
    });
  }

  /// Confirmed live 2026-07-20: body `{"thread_ids": [...]}` (snake_case,
  /// unlike the message-level actions above), response
  /// `{"result": true, "sent": {"<threadId>": <newMessageId>}, "errors": []}`.
  Future<Response> forwardMessage({required String messageId, required List<String> threadIds}) {
    return _api.post("/better-messages/v1/message/$messageId/forward", {
      "thread_ids": threadIds.map((id) => int.tryParse(id) ?? id).toList(),
    });
  }

  /// Voice notes are a two-step flow, confirmed live 2026-07-20: upload the
  /// audio file first (multipart field name `file`), which returns an
  /// attachment id, then send that id via [sendVoice]. There is no direct
  /// "attach audio to a message" single-call endpoint.
  Future<Response> uploadAttachment({required String threadId, required File file}) {
    final formData = FormData.fromMap({
      "file": MultipartFile.fromFileSync(file.path, filename: file.path.split(Platform.pathSeparator).last),
    });
    return _api.post("/better-messages/v1/thread/$threadId/upload", formData);
  }

  Future<Response> sendVoice({
    required String threadId,
    required int attachmentId,
    required String tempId,
    required int tempTime,
  }) {
    return _api.post("/better-messages/v1/thread/$threadId/sendVoice", {
      "attachment_id": attachmentId,
      "temp_id": tempId,
      "temp_time": tempTime,
    });
  }

  /// Starts a call - confirmed live 2026-07-21 (real disposable
  /// test-and-immediately-callMissed call against this account's own
  /// thread 72): response is
  /// `{result, message_id, thread_id, user_ids, token, encryption_key}`.
  /// `token` is a LiveKit JWT (decodes to `video.room` =
  /// "room_{site}_{thread_id}_{message_id}", `roomConfig.maxParticipants:
  /// 2` - 1-on-1 only, no group calls) for the real-time media
  /// connection to `video-cloud.better-messages.com` (see
  /// docs/api-audit for the full decoded shape). `result` was "allowed"
  /// in the confirmed test - other values (e.g. a decline/blocked case)
  /// are not confirmed.
  Future<Response> callCreate({required String threadId, required String type}) {
    return _api.post("/better-messages/v1/callCreate", {
      "thread_id": int.tryParse(threadId) ?? threadId,
      "type": type,
    });
  }

  /// Marks a call as actually connected (both sides joined the LiveKit
  /// room) - confirmed real endpoint + body shape via HAR capture
  /// 2026-07-21, response not captured.
  Future<Response> callStarted({
    required String threadId,
    required String messageId,
    required String type,
  }) {
    return _api.post("/better-messages/v1/callStarted", {
      "thread_id": int.tryParse(threadId) ?? threadId,
      "message_id": int.tryParse(messageId) ?? messageId,
      "type": type,
    });
  }

  /// Periodic heartbeat while a call is active - confirmed real endpoint
  /// + body shape via HAR capture 2026-07-21 (the real site sends this
  /// roughly every 8-13s during a live call).
  Future<Response> callUsage({
    required String threadId,
    required String messageId,
    required int durationSeconds,
    required int bytesSent,
    required int bytesReceived,
  }) {
    return _api.post("/better-messages/v1/callUsage", {
      "thread_id": int.tryParse(threadId) ?? threadId,
      "message_id": int.tryParse(messageId) ?? messageId,
      "duration": durationSeconds,
      "stats": {"bytes_sent": bytesSent, "bytes_received": bytesReceived},
    });
  }

  /// Ends a call that was never answered/connected, or hangs up a
  /// pending outgoing call - confirmed real endpoint + body shape live
  /// 2026-07-21 (real disposable test call, immediately ended this way),
  /// confirmed response: bare boolean `true`.
  Future<Response> callMissed({
    required String threadId,
    required String messageId,
    required String type,
    required int durationSeconds,
  }) {
    return _api.post("/better-messages/v1/callMissed", {
      "thread_id": int.tryParse(threadId) ?? threadId,
      "message_id": int.tryParse(messageId) ?? messageId,
      "type": type,
      "duration": durationSeconds,
    });
  }
}
