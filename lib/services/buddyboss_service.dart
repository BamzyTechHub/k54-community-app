import 'dart:convert';
import '../models/post_model.dart';
import 'api_service.dart';

class BuddyBossService {

  Future<Post> toggleFavorite(int activityId) async {
  final response = await _api.post(
    "/buddyboss/v1/activity/$activityId/favorite",
    {},
  );

  return Post.fromBuddyBoss(response.data);
}

  final ApiService _api = ApiService.instance;
  Future<void> testLike(int activityId) async {
  final response = await _api.post(
    "/buddyboss/v1/activity/$activityId/favorite",
    {},
  );

  print("========== LIKE RESPONSE ==========");
  print(response.data);
}

  Future<List<Post>> getTimeline({
  String? userId,
})async {
  final endpoint = userId == null
    ? "/buddyboss/v1/activity"
    : "/buddyboss/v1/activity?user_id=$userId";

// Load timeline
final response = await _api.get(endpoint);
  
  

  print("========== TIMELINE ==========");

  final body = response.data;

final activities = body is List
    ? body
    : (body["activities"] ??
        body["activity"] ??
        body["data"] ??
        body["results"] ??
        []);

print(const JsonEncoder.withIndent('  ').convert(activities.first));
for (final activity in activities) {
  print("------------");
print("ID: ${activity["id"]}");
print("Name: ${activity["name"]}");
print("Avatar: ${activity["avatar_urls"] ?? activity["avatar_url"] ?? activity["user_avatar"]}");
print("Feature Media: ${activity["feature_media"]}");
print("Activity Data: ${activity["activity_data"]}");
print("Comments: ${activity["comment_count"] ?? 0}");
print("Shares: ${activity["share_count"] ?? 0}");
print("Preview: ${activity["preview_data"]}");
print("Profile Link: ${activity["profile_link"] ?? activity["link"]}");
}

  return activities
      .map<Post>((item) => Post.fromBuddyBoss(item))
      .toList();
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