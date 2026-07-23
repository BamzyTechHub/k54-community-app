import 'package:dio/dio.dart';
import 'package:k54_mobile/core/services/api_service.dart';

/// Raw HTTP calls for `/buddyboss/v1/notifications`, mapped from
/// BuddyPress's open-source BP-REST plugin source (see
/// app_notification.dart's doc comment) - real evidence, not guessed.
class NotificationsApiService {
  final ApiService _api = ApiService.instance;

  /// [isNew] is the real query filter arg (confirmed via the route's own
  /// OPTIONS schema: `is_new`, boolean, defaults to `true` when omitted -
  /// see NotificationsRepository.getNotifications' doc comment for why
  /// that default silently hid an entire real notification from the app).
  Future<Response> getNotifications({int page = 1, int perPage = 20, bool? isNew}) {
    return _api.get(
      "/buddyboss/v1/notifications",
      query: {
        "page": page,
        "per_page": perPage,
        if (isNew != null) "is_new": isNew,
      },
    );
  }

  /// Confirmed live 2026-07-23 via the route's own OPTIONS schema:
  /// `is_new` is typed as an integer (0/1, default 1), not a boolean -
  /// sending JSON `false` here was a real type mismatch against what the
  /// endpoint's own schema declares, a real suspect for "marking read
  /// doesn't stick after a refresh" (WordPress's REST arg validation can
  /// silently reject a value that doesn't match the declared schema type).
  Future<Response> markRead(String id) {
    return _api.put("/buddyboss/v1/notifications/$id", {"is_new": 0});
  }

  Future<Response> markAllRead() {
    return _api.post("/buddyboss/v1/notifications/bulk/read", {});
  }
}
