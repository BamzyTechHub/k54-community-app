import '../models/comment_model.dart';
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

  /// Shares (reposts) an activity item. Unlike /favorite and /pin, this
  /// deliberately does NOT parse the response as an updated Post — a share
  /// endpoint most likely returns the newly-created repost item, not the
  /// original post with an incremented count, and treating one as the
  /// other risks silently overwriting the displayed post's real data with
  /// the repost's. Callers should optimistically update their own local
  /// share count and roll back on failure instead, same as a like/pin
  /// would if their response shape were similarly uncertain.
  Future<void> shareActivity(String activityId) async {
    await _api.post(
      "/buddyboss/v1/activity/$activityId/share",
      {},
    );
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

  /// Fetches comments for an activity post. Response schema wasn't
  /// independently captured (unlike /favorite) — parses defensively via
  /// [Comment.fromBuddyBoss], same discipline as the rest of this service.
  Future<List<Comment>> getComments(String activityId, {int page = 1}) async {
    final response = await _api.get(
      "/buddyboss/v1/activity/$activityId/comment",
      query: {"page": page},
    );

    final body = response.data;
    final List raw = body is List
        ? body
        : (body["comments"] ?? body["data"] ?? body["results"] ?? []);

    return raw
        .whereType<Map>()
        .map((c) => Comment.fromBuddyBoss(Map<String, dynamic>.from(c)))
        .toList();
  }

  /// Posts a new comment, or a reply if [replyToCommentId] is given.
  /// Replies target the parent comment's own id as the endpoint's {id} -
  /// BuddyBoss's comment tree treats each comment as an activity item in
  /// its own right, so commenting "on" a comment nests it underneath.
  /// Unconfirmed against a live response - same caveat as getComments.
  Future<Comment> postComment({
    required String activityId,
    required String content,
    String? replyToCommentId,
  }) async {
    final targetId = replyToCommentId ?? activityId;
    final response = await _api.post(
      "/buddyboss/v1/activity/$targetId/comment",
      {"content": content},
    );

    return Comment.fromBuddyBoss(Map<String, dynamic>.from(response.data));
  }

  /// Toggles a comment's like state via the same /favorite resource used
  /// for posts - comments are activity items too, so this is the same
  /// confirmed-working endpoint, just targeting a comment's id.
  Future<Comment> toggleCommentFavorite(String commentId) async {
    final response = await _api.post(
      "/buddyboss/v1/activity/$commentId/favorite",
      {},
    );

    return Comment.fromBuddyBoss(Map<String, dynamic>.from(response.data));
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