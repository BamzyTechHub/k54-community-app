import 'package:dio/dio.dart';
import '../../services/api_service.dart';

/// Thin wrapper around raw BuddyBoss messaging + member-search HTTP calls.
/// No business logic and no caching here — that belongs in
/// MessagingRepository. This class exists so there is exactly ONE place
/// that knows the literal endpoint paths/params, per BuddyBoss's docs:
///   GET  /buddyboss/v1/messages?box=inbox&user_id=<id>
///   GET  /buddyboss/v1/messages/{thread_id}
///   POST /buddyboss/v1/messages   { id, message }               -> reply
///   POST /buddyboss/v1/messages   { message, recipients: [id] } -> new thread
///   GET  /buddyboss/v1/members?search=<term>
class MessagingApiService {
  final ApiService _api = ApiService.instance;

  Future<Response> getThreads(String userId) {
    return _api.get(
      "/buddyboss/v1/messages",
      query: {"box": "inbox", "user_id": userId, "per_page": 50},
    );
  }

  Future<Response> getThread(String threadId) {
    return _api.get("/buddyboss/v1/messages/$threadId");
  }

  Future<Response> replyToThread({
    required String threadId,
    required String message,
  }) {
    return _api.post("/buddyboss/v1/messages", {
      "id": threadId,
      "message": message,
    });
  }

  Future<Response> startThread({
    required String recipientId,
    required String message,
  }) {
    return _api.post("/buddyboss/v1/messages", {
      "message": message,
      "recipients": [recipientId],
    });
  }

  Future<Response> markThread({
    required String threadId,
    required String action, // "unread" | "hide_thread" | "delete_messages"
    required bool value,
  }) {
    return _api.post("/buddyboss/v1/messages/action/$threadId", {
      "action": action,
      "value": value,
    });
  }

  Future<Response> searchMembers(String query) {
    return _api.get(
      "/buddyboss/v1/members",
      query: {"search": query, "per_page": 20},
    );
  }
}
