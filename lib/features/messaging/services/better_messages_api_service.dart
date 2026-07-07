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
/// implemented here. `getUniqueConversation` (start a brand-new
/// conversation) and a single-thread mark-read call have NO confirmed
/// shape - the website only demonstrated read-marking over its WebSocket
/// (`threadOpen` event, out of scope until Stage C) - so neither is
/// implemented here; callers must not invent a payload for them.
class BetterMessagesApiService {
  final ApiService _api = ApiService.instance;

  /// Polls for anything new since [lastUpdate] (server-time, same scale as
  /// the response envelope's own `currentTime`/`serverTime` fields - not a
  /// standard epoch, see MessageThread's timestamp parsing note).
  Future<Response> checkNew({
    required int lastUpdate,
    required List<String> threadIds,
    List<String> visibleThreads = const [],
  }) {
    return _api.post("/better-messages/v1/checkNew", {
      "lastUpdate": lastUpdate,
      "visibleThreads": visibleThreads,
      "threadIds": threadIds,
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

  Future<Response> getGroups() {
    return _api.get("/better-messages/v1/getGroups");
  }
}
