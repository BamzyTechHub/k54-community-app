import 'package:dio/dio.dart';
import 'package:k54_mobile/core/services/api_service.dart';

/// Raw HTTP calls for `/buddyboss/v1/notifications`, mapped from
/// BuddyPress's open-source BP-REST plugin source (see
/// app_notification.dart's doc comment) - real evidence, not guessed.
class NotificationsApiService {
  final ApiService _api = ApiService.instance;

  Future<Response> getNotifications({int page = 1, int perPage = 20}) {
    return _api.get(
      "/buddyboss/v1/notifications",
      query: {"page": page, "per_page": perPage},
    );
  }

  /// Confirmed: only the `is_new` field is editable on this endpoint.
  Future<Response> markRead(String id) {
    return _api.put("/buddyboss/v1/notifications/$id", {"is_new": false});
  }

  Future<Response> markAllRead() {
    return _api.post("/buddyboss/v1/notifications/bulk/read", {});
  }
}
