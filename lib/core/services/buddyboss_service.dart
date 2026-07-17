import 'package:k54_mobile/features/activity/models/comment_model.dart';
import 'package:k54_mobile/features/activity/models/post_model.dart';
import 'package:k54_mobile/features/activity/models/reaction_type.dart';
import 'package:k54_mobile/features/activity/models/user_reaction.dart';
import 'package:k54_mobile/features/friends/repositories/friends_repository.dart';
import 'package:k54_mobile/core/services/api_service.dart';

class BuddyBossService {
  final ApiService _api = ApiService.instance;

  // App-wide config, not per-user data - fetched once and reused, same
  // caching approach as FriendsRepository._cachedUserId.
  static List<ReactionType>? _cachedReactionTypes;

  /// The six real reaction choices from `GET /buddyboss/v1/reactions`
  /// (confirmed live 2026-07-17: Like/Love/Laugh/Angry/Sad/Wow) - this is
  /// BuddyBoss Platform's actual reaction system on this site, not a
  /// fabricated list of emoji.
  Future<List<ReactionType>> getReactionTypes() async {
    final cached = _cachedReactionTypes;
    if (cached != null) return cached;

    final response = await _api.get("/buddyboss/v1/reactions");
    final List raw = response.data is List ? response.data : [];
    final types = raw
        .whereType<Map>()
        .map((r) => ReactionType.fromJson(Map<String, dynamic>.from(r)))
        .toList();
    _cachedReactionTypes = types;
    return types;
  }

  /// The current user's own reaction row on an item, or null if they
  /// haven't reacted. Needed before removing/changing a reaction - DELETE
  /// takes the row's own id, not the item id or reaction type id.
  Future<UserReaction?> _getMyReaction({
    required String itemId,
    String itemType = "activity",
  }) async {
    final myId = await FriendsRepository.instance.currentUserId();
    final response = await _api.get(
      "/buddyboss/v1/user-reactions",
      query: {
        "item_type": itemType,
        "item_id": itemId,
        "user_id": myId,
        "per_page": 1,
      },
    );
    final List raw = response.data is List ? response.data : [];
    if (raw.isEmpty) return null;
    return UserReaction.fromJson(Map<String, dynamic>.from(raw.first));
  }

  /// Sets (or replaces) the current user's reaction on an item via the
  /// real `/buddyboss/v1/user-reactions` endpoint. Deletes any existing
  /// reaction row first rather than assuming the server dedupes on
  /// POST - that behavior isn't confirmed, and posting a second reaction
  /// on top of an unremoved first one would risk leaving two rows (an
  /// inflated reaction count) rather than one changed reaction.
  Future<void> setReaction({
    required String itemId,
    required int reactionId,
    String itemType = "activity",
  }) async {
    final existing = await _getMyReaction(itemId: itemId, itemType: itemType);
    if (existing != null) {
      await _api.delete("/buddyboss/v1/user-reactions/${existing.id}");
    }
    final myId = await FriendsRepository.instance.currentUserId();
    await _api.post("/buddyboss/v1/user-reactions", {
      "reaction_id": reactionId,
      "item_type": itemType,
      "item_id": itemId,
      "user_id": myId,
    });
  }

  /// Removes the current user's reaction on an item, if any.
  Future<void> removeReaction({
    required String itemId,
    String itemType = "activity",
  }) async {
    final existing = await _getMyReaction(itemId: itemId, itemType: itemType);
    if (existing != null) {
      await _api.delete("/buddyboss/v1/user-reactions/${existing.id}");
    }
  }

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

  /// Fetches a page of the timeline. [page]/[perPage] follow the standard
  /// WP REST pagination convention used elsewhere in this API (same as
  /// getComments) - safe to infer since it's the platform's own convention,
  /// not a guessed custom shape.
  /// Real post count for a profile's "Posts" stat - `total_post_count`
  /// (what ProfilePage used to read) doesn't exist anywhere in the
  /// confirmed `/buddyboss/v1/members` schema (checked live 2026-07-18),
  /// which is why it always showed 0. This instead does a per_page=1
  /// activity request for that user and reads the standard WP REST
  /// `X-WP-Total` response header - the same real-count pattern
  /// MembersRepository already uses for the member directory's total.
  Future<int?> getUserPostCount(String userId) async {
    final response = await _api.get(
      "/buddyboss/v1/activity",
      query: {"user_id": userId, "per_page": 1, "page": 1},
    );
    final totalHeader = response.headers.value("x-wp-total");
    return totalHeader != null ? int.tryParse(totalHeader) : null;
  }

  Future<List<Post>> getTimeline({
    String? userId,
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _api.get(
      "/buddyboss/v1/activity",
      query: {
        "page": page,
        "per_page": perPage,
        "user_id": ?userId,
      },
    );
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

  /// Returns the created Post (parsed the same defensive way as
  /// updatePost) so the caller has its real id - needed to chain a
  /// follow-up call like toggleCommentsClosed right after creation.
  Future<Post> createPost({
  required String content,
  String privacy = "public",
}) async {
  final response = await _api.post(
    "/buddyboss/v1/activity",
    {
      "content": content,
      "type": "activity_update",
      "component": "activity",
      "privacy": privacy,
    },
  );
  return Post.fromBuddyBoss(response.data);
}

  /// Updates an existing post's content/privacy. Mirrors createPost's body
  /// fields since it's the same resource, just PUT to a specific id instead
  /// of POST to the collection - response schema wasn't independently
  /// captured, so it's parsed the same defensive way as pin/favorite.
  Future<Post> updatePost({
    required String activityId,
    required String content,
    String privacy = "public",
  }) async {
    final response = await _api.put(
      "/buddyboss/v1/activity/$activityId",
      {
        "content": content,
        "privacy": privacy,
      },
    );

    return Post.fromBuddyBoss(response.data);
  }

  Future<void> deletePost(String activityId) async {
    await _api.delete("/buddyboss/v1/activity/$activityId");
  }

  /// Opens or closes commenting on a post. No live response for this
  /// endpoint has been captured, so unlike pin/edit this doesn't parse or
  /// trust a response body at all - it only confirms the call succeeded
  /// (a non-2xx throws) and lets the caller flip its own local state, the
  /// same no-response-trust strategy shareActivity uses for the same reason.
  Future<void> toggleCommentsClosed(String activityId, bool close) async {
    await _api.post(
      "/buddyboss/v1/activity/$activityId/close-comments",
      {"close": close},
    );
  }

  /// Writes a single xprofile field's value for a user. [fieldId] must be
  /// one of the numeric IDs confirmed via `GET /xprofile/groups?fetch_fields=1`
  /// (e.g. 17 = Biography) - only plain textbox/textarea fields have a
  /// confirmed write shape (`{"value": ...}`); selectbox/gender/datebox/
  /// socialnetworks fields have NOT been confirmed against a live write and
  /// should not be sent through this method until they are.
  /// Sends site-wide email invites via the confirmed live
  /// `POST /buddyboss/v1/invites` endpoint (schema checked 2026-07-18:
  /// `fields` is an array of {name, email_id} objects, plus optional
  /// email_subject/email_content) - a real BuddyBoss "Invite Anyone"
  /// feature, distinct from group invites. Takes multiple recipients at
  /// once since the real endpoint's `fields` array natively supports it -
  /// matches the Figma design's repeating recipient-row form.
  Future<void> sendInvites({
    required List<({String name, String email})> recipients,
    String? message,
  }) async {
    await _api.post("/buddyboss/v1/invites", {
      "fields": recipients.map((r) => {"name": r.name, "email_id": r.email}).toList(),
      if (message != null && message.isNotEmpty) "email_content": message,
    });
  }

  /// Lists invites already sent by the current user.
  Future<List<Map<String, dynamic>>> getInvites({int page = 1, int perPage = 20}) async {
    final response = await _api.get(
      "/buddyboss/v1/invites",
      query: {"page": page, "per_page": perPage},
    );
    final List raw = response.data is List ? response.data : const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  /// Creates a real Documents folder via the confirmed live
  /// `POST /buddyboss/v1/document/folder` endpoint (schema checked
  /// 2026-07-18: title/parent/group_id/privacy). Document *upload* is a
  /// separate matter - `/buddyboss/v1/document/upload` exists but its
  /// OPTIONS schema declares zero documented args (it reads $_FILES
  /// directly), so the multipart field name isn't discoverable from the
  /// API alone and isn't guessed at here - same discipline as the chat
  /// attachment endpoints.
  Future<void> createDocumentFolder({required String title, String privacy = "public"}) async {
    await _api.post("/buddyboss/v1/document/folder", {
      "title": title,
      "privacy": privacy,
    });
  }

  /// Lists a user's real Documents (folders show up as items with their
  /// own id in this same collection per BuddyBoss's schema).
  Future<List<Map<String, dynamic>>> getDocuments({String? userId, int page = 1, int perPage = 20}) async {
    final response = await _api.get(
      "/buddyboss/v1/document",
      query: {
        "page": page,
        "per_page": perPage,
        if (userId != null && userId.isNotEmpty) "user_id": userId,
      },
    );
    final List raw = response.data is List ? response.data : const [];
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> updateProfileField({
    required String userId,
    required int fieldId,
    required String value,
  }) async {
    await _api.put(
      "/buddyboss/v1/xprofile/$fieldId/data/$userId",
      {"value": value},
    );
  }

}