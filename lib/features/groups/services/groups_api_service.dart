import 'package:dio/dio.dart';
import 'package:k54_mobile/core/services/api_service.dart';

/// Raw HTTP calls for `/buddyboss/v1/groups`, mapped directly from
/// BuddyPress's open-source BP-REST plugin source (see group_model.dart's
/// doc comment) - real evidence, not guessed.
class GroupsApiService {
  final ApiService _api = ApiService.instance;

  /// [orderby]/[order] map to BP-REST's confirmed groups sort params
  /// (class-bp-rest-groups-endpoint.php: orderby in date_created|
  /// last_activity|total_member_count|name|random, order in asc|desc).
  Future<Response> getGroups({
    String? search,
    String? orderby,
    String? order,
    int page = 1,
    int perPage = 20,
  }) {
    return _api.get(
      "/buddyboss/v1/groups",
      query: {
        "page": page,
        "per_page": perPage,
        if (search != null && search.isNotEmpty) "search_terms": search,
        "orderby": ?orderby,
        "order": ?order,
      },
    );
  }

  /// The current user's own groups - confirmed dedicated route rather
  /// than a `user_id` filter on the collection endpoint.
  Future<Response> getMyGroups({int max = 50}) {
    return _api.get("/buddyboss/v1/groups/me", query: {"max": max});
  }

  Future<Response> createGroup({
    required String name,
    required String description,
    required String status,
  }) {
    return _api.post("/buddyboss/v1/groups", {
      "name": name,
      "description": description,
      "status": status,
    });
  }

  /// Confirmed via BP-REST's group-membership endpoint
  /// (class-bp-rest-group-membership-endpoint.php): POST to the
  /// collection with the joining user's id.
  Future<Response> joinGroup({required String groupId, required String userId}) {
    return _api.post("/buddyboss/v1/groups/$groupId/members", {"user_id": userId});
  }

  Future<Response> leaveGroup({required String groupId, required String userId}) {
    return _api.delete("/buddyboss/v1/groups/$groupId/members/$userId");
  }
}
