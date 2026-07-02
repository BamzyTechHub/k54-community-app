import '../models/post_model.dart';
import 'api_service.dart';

class BuddyBossService {
  final ApiService _api = ApiService.instance;

  Future<List<Post>> getTimeline() async {
    final response = await _api.get("/buddyboss/v1/activity");

    final body = response.data;

    final List activities = body is List
        ? body
        : (body["activities"] ??
            body["data"] ??
            body["results"] ??
            []);

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