import 'package:dio/dio.dart';
import 'package:k54_mobile/core/services/api_service.dart';

/// Raw HTTP calls for the confirmed K54 AI backend (`/wp-json/k54-ai/v1/*`),
/// mapped directly from the PHP source review in
/// docs/api-audit/ai-assistant.md - not inferred, not guessed.
///
/// The backend's `permission_callback` is `__return_true` and there's an
/// explicit auth-bypass filter for this whole namespace, so no bearer
/// token is actually required - but the app sends its JWT anyway (the
/// shared ApiService/Dio instance already attaches it globally), both so
/// `/create-group` correctly attributes `creator_id` to the real user
/// instead of 0, and so behavior doesn't change if the backend's
/// unauthenticated access gets locked down later.
class AiApiService {
  final ApiService _api = ApiService.instance;

  /// `history` should already be trimmed to the last ~10 turns by the
  /// caller (the backend re-trims server-side too, but sending less is
  /// cheaper). Confirmed non-streaming: one blocking call, up to 60s.
  ///
  /// The response is always HTTP 200, even on failure - the backend has
  /// no structured error field. A caller must check the returned `reply`
  /// string against the two known error phrases
  /// ("K54 AI connection error." / "K54 AI could not generate a
  /// response.") to detect failure; this method does not do that
  /// itself, it just returns the raw reply for AiRepository to interpret.
  Future<Response> chat({
    required String message,
    required List<Map<String, String>> history,
  }) {
    return _api.post(
      "/k54-ai/v1/chat",
      {"message": message, "history": history},
      options: Options(
        sendTimeout: const Duration(seconds: 65),
        receiveTimeout: const Duration(seconds: 65),
      ),
    );
  }

  /// `privacy` must be one of "public"/"private"/"hidden" - anything
  /// else the backend itself defaults to "public" server-side, but this
  /// doesn't rely on that fallback.
  Future<Response> createGroup({
    required String groupName,
    required String description,
    required String privacy,
  }) {
    return _api.post("/k54-ai/v1/create-group", {
      "groupName": groupName,
      "description": description,
      "privacy": privacy,
    });
  }
}
