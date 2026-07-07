import '../models/post_model.dart';
import 'api_service.dart';

class BuddyBossService {
  final ApiService _api = ApiService.instance;

  Future<Post> toggleFavorite(int activityId) async {
  final response = await _api.post(
    "/buddyboss/v1/activity/$activityId/favorite",
    {},
  );

  return Post.fromBuddyBoss(response.data);
}

  /// Toggles a post's pinned state. The endpoint's response shape hasn't
  /// been independently captured (unlike /favorite, which is confirmed
  /// working) — this assumes the same single-POST-toggle, full-Post-object
  /// response pattern since it's the same /activity/{id}/{action} resource
  /// shape. If that assumption is wrong, this will surface as a parsing
  /// exception on the caller side, not a silent wrong result.
  Future<Post> togglePin(int activityId) async {
  final response = await _api.post(
    "/buddyboss/v1/activity/$activityId/pin",
    {},
  );

  return Post.fromBuddyBoss(response.data);
}

  Future<List<Post>> getTimeline({
    String? userId,
  }) async {
    final endpoint = userId == null
        ? "/buddyboss/v1/activity"
        : "/buddyboss/v1/activity?user_id=$userId";

    final response = await _api.get(endpoint);
    final body = response.data;

    final List activities = body is List
        ? body
        : (body["activities"] ??
            body["activity"] ??
            body["data"] ??
            body["results"] ??
            []);

    return activities.map<Post>((item) => Post.fromBuddyBoss(item)).toList();
  }

  Future<void> createPost({
  required String content,
  String privacy = "public",
}) async {
  await _api.post(
    "/buddyboss/v1/activity",
    {
      "content": content,
      "type": "activity_update",
      "component": "activity",
      "privacy": privacy,
    },
  );
}

}