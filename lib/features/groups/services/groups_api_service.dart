import 'dart:io';

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
        // Confirmed live 2026-07-21: without this, a hidden group the
        // current user actually organizes/belongs to is silently
        // excluded even from their own "All Groups" view (real site's
        // own frontend always passes this too - matches a live
        // screenshot showing a Hidden group "uu" in the real "All
        // Groups" list). The server still correctly scopes this to only
        // hidden groups this user can see - confirmed by testing this
        // param returns exactly this account's real 8 groups, not a
        // site-wide dump of every hidden group.
        "show_hidden": true,
      },
    );
  }

  /// The current user's own groups. `GET /buddyboss/v1/groups/me`
  /// (previously used here) is a **dead route - confirmed live 2026-07-21,
  /// returns a real 404 `rest_no_route`** - this is why "My Groups" never
  /// loaded. The real mechanism is the main collection endpoint's own
  /// `user_id` param ("Pass a user_id to limit to only Groups that this
  /// user is a member of" - confirmed from its own arg schema, and
  /// confirmed live to return this account's real 5 memberships,
  /// including the group it's Organizer of).
  Future<Response> getMyGroups({required String userId, int perPage = 50}) {
    return _api.get(
      "/buddyboss/v1/groups",
      query: {"user_id": userId, "per_page": perPage, "show_hidden": true},
    );
  }

  /// Single-group fetch, confirmed live 2026-07-20 - same rich per-user
  /// fields (`is_member`, `can_join`, `role`, `request_id`, `members_count`,
  /// `cover_url`, `description.rendered`) as the list endpoint, just for
  /// one group. Needed for a real group-detail screen.
  Future<Response> getGroup(String groupId) {
    return _api.get("/buddyboss/v1/groups/$groupId");
  }

  /// Real group member list, confirmed live 2026-07-20 - each entry is
  /// the same user-object shape used elsewhere (`id`, `name`,
  /// `avatar_urls`), plus `is_admin`/`is_mod`/`role` for that specific
  /// group. `X-WP-Total` header carries the real total (same convention
  /// as every other collection route in this app).
  Future<Response> getGroupMembers({required String groupId, int page = 1, int perPage = 20}) {
    return _api.get(
      "/buddyboss/v1/groups/$groupId/members",
      query: {"page": page, "per_page": perPage},
    );
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

  /// Real admin action - `PUT /buddyboss/v1/groups/{id}` is the same
  /// resource's own update method (confirmed in the route index's own
  /// `Methods: GET,POST,PUT,PATCH,DELETE` list for this endpoint), same
  /// field names as create. Only an admin/organizer can actually call
  /// this successfully - BuddyBoss enforces that server-side.
  Future<Response> updateGroup({
    required String groupId,
    required String name,
    required String description,
    required String status,
  }) {
    return _api.put("/buddyboss/v1/groups/$groupId", {
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

  /// For private groups only - `groups/{id}/members` (joinGroup above)
  /// only works when the group's own `can_join` is true (public groups).
  /// A private group's real join flow creates a pending request here
  /// instead, which the group's admin later accepts/rejects via
  /// `groups/membership-requests/{request_id}` - confirmed real route +
  /// arg schema from the live `GET /wp-json/` route index (2026-07-20),
  /// not yet exercised against an actual private group since none
  /// currently exist on this site.
  Future<Response> requestMembership({required String groupId, required String userId}) {
    return _api.post("/buddyboss/v1/groups/membership-requests", {
      "group_id": groupId,
      "user_id": userId,
    });
  }

  Future<Response> cancelMembershipRequest(String requestId) {
    return _api.delete("/buddyboss/v1/groups/membership-requests/$requestId");
  }

  /// Real invite-a-specific-person-to-a-specific-group action, confirmed
  /// from the live route index's arg schema 2026-07-20
  /// (`buddyboss/v1/groups/invites`, POST args: user_id, inviter_id,
  /// group_id, message, send_invite). Not yet exercised with a real
  /// request/response capture - built defensively from the confirmed arg
  /// names, same discipline as every other unconfirmed-body call already
  /// in this codebase.
  Future<Response> sendGroupInvite({
    required String groupId,
    required String userId,
    required String inviterId,
    String message = "",
  }) {
    return _api.post("/buddyboss/v1/groups/invites", {
      "group_id": groupId,
      "user_id": userId,
      "inviter_id": inviterId,
      "message": message,
      "send_invite": true,
    });
  }

  /// Group-scoped activity feed - confirmed real `group_id` filter arg on
  /// `GET /buddyboss/v1/activity` (live route schema, 2026-07-22).
  Future<Response> getGroupActivity({required String groupId, int page = 1, int perPage = 20}) {
    return _api.get("/buddyboss/v1/activity", query: {
      "group_id": groupId,
      "component": "groups",
      "page": page,
      "per_page": perPage,
    });
  }

  /// Confirmed real `group_id` filter arg + response shape (same
  /// `attachment_data`-nested structure as an activity post's own
  /// `bp_media_ids`, see PostPhoto - live-tested 2026-07-22).
  Future<Response> getGroupMedia({required String groupId, int page = 1, int perPage = 30}) {
    return _api.get("/buddyboss/v1/media", query: {"group_id": groupId, "page": page, "per_page": perPage});
  }

  /// Confirmed real `group_id` filter arg (route schema) - response shape
  /// inferred to match PostVideo's `attachment_data` pattern from the same
  /// BuddyBoss media subsystem as [getGroupMedia], not yet observed with
  /// real video content live.
  Future<Response> getGroupVideos({required String groupId, int page = 1, int perPage = 30}) {
    return _api.get("/buddyboss/v1/video", query: {"group_id": groupId, "page": page, "per_page": perPage});
  }

  /// Confirmed real `group_id` filter arg (route schema) - response shape
  /// inferred to match PostDocument's pattern, not yet observed with real
  /// document content live.
  Future<Response> getGroupDocuments({required String groupId, int page = 1, int perPage = 30}) {
    return _api.get("/buddyboss/v1/document", query: {"group_id": groupId, "page": page, "per_page": perPage});
  }

  /// A group's discussion topics - bbPress's own hierarchy uses `parent`
  /// for "topics belonging to this forum id" (confirmed real arg on
  /// `GET /buddyboss/v1/topics`, live route schema 2026-07-22). Only
  /// meaningful when the group has `enable_forum: true` and a real
  /// `forum` id (see Group.forumId's doc comment).
  Future<Response> getForumTopics({required String forumId, int page = 1, int perPage = 20}) {
    return _api.get("/buddyboss/v1/topics", query: {"parent": forumId, "page": page, "per_page": perPage});
  }

  Future<Response> getTopic(String topicId) {
    return _api.get("/buddyboss/v1/topics/$topicId");
  }

  /// A single reply, used to resolve a "bbp_reply_create" activity's
  /// `secondary_item_id` (the reply's own id) back to its parent topic id
  /// (the reply's own `parent` field, confirmed live) - a group's Feed
  /// tab needs this to deep-link a reply-activity card into the real
  /// discussion thread, matching the real site's "Join Discussion" link.
  Future<Response> getReply(String replyId) {
    return _api.get("/buddyboss/v1/reply/$replyId");
  }

  Future<Response> createTopic({
    required String groupId,
    required String title,
    required String content,
  }) {
    return _api.post("/buddyboss/v1/topics", {
      "group": groupId,
      "title": title,
      "content": content,
      "status": "publish",
    });
  }

  /// Replies to one topic - bbPress's own `parent` on `GET .../reply`
  /// means "replies belonging to this topic id" (confirmed real arg,
  /// live route schema 2026-07-22).
  Future<Response> getTopicReplies({required String topicId, int page = 1, int perPage = 20}) {
    return _api.get("/buddyboss/v1/reply", query: {"parent": topicId, "page": page, "per_page": perPage});
  }

  Future<Response> createReply({
    required String topicId,
    required String forumId,
    required String content,
  }) {
    return _api.post("/buddyboss/v1/reply", {
      "topic_id": topicId,
      "forum_id": forumId,
      "content": content,
    });
  }

  /// Confirmed real `group_id` filter + response shape live 2026-07-22
  /// (a real album on a real group).
  Future<Response> getGroupAlbums({required String groupId, int page = 1, int perPage = 30}) {
    return _api.get("/buddyboss/v1/media/albums", query: {"group_id": groupId, "page": page, "per_page": perPage});
  }

  Future<Response> getAlbum({required String albumId, int mediaPage = 1, int mediaPerPage = 50}) {
    return _api.get("/buddyboss/v1/media/albums/$albumId", query: {
      "media_page": mediaPage,
      "media_per_page": mediaPerPage,
    });
  }

  Future<Response> createAlbum({required String groupId, required String title}) {
    return _api.post("/buddyboss/v1/media/albums", {
      "title": title,
      "group_id": groupId,
      "privacy": "grouponly",
    });
  }

  Future<Response> deleteAlbum(String albumId) {
    return _api.delete("/buddyboss/v1/media/albums/$albumId");
  }

  /// Attaches an already-uploaded photo (see BuddyBossService.uploadMedia
  /// - same two-step upload-then-attach flow, just targeting an album
  /// instead of a post's activity_id) to a specific album.
  Future<Response> attachMediaToAlbum({
    required String groupId,
    required String albumId,
    required int uploadId,
  }) {
    return _api.post("/buddyboss/v1/media", {
      "upload_ids": [uploadId],
      "group_id": groupId,
      "album_id": albumId,
    });
  }

  /// Promote/demote a member's role, or ban them - confirmed real args
  /// (`role`, `action`) on `PUT/PATCH groups/{group_id}/members/{user_id}`,
  /// live route schema 2026-07-22. [role] is "member"/"mod"/"admin".
  Future<Response> updateMemberRole({required String groupId, required String userId, required String role}) {
    return _api.put("/buddyboss/v1/groups/$groupId/members/$userId", {"role": role});
  }

  /// Removes a member from the group ("kick") - confirmed real DELETE on
  /// the same resource, live route schema 2026-07-22.
  Future<Response> removeMemberFromGroup({required String groupId, required String userId}) {
    return _api.delete("/buddyboss/v1/groups/$groupId/members/$userId");
  }

  Future<Response> deleteGroup(String groupId) {
    return _api.delete("/buddyboss/v1/groups/$groupId");
  }

  /// [nav] is one of "edit-details"/"group-settings"/"forum" - confirmed
  /// real enum on the route's own OPTIONS schema, live 2026-07-22. Each
  /// nav returns a different, fully self-describing list of settings (see
  /// GroupSetting's doc comment) rather than fixed named fields.
  Future<Response> getGroupSettings({required String groupId, required String nav}) {
    return _api.get("/buddyboss/v1/groups/$groupId/settings", query: {"nav": nav});
  }

  /// [fields] is a name->value map of just the settings being changed
  /// (matches the route's own confirmed arg description: "The list of
  /// fields Objects to update with name and value of the field").
  Future<Response> updateGroupSettings({
    required String groupId,
    required String nav,
    required Map<String, dynamic> fields,
  }) {
    return _api.post("/buddyboss/v1/groups/$groupId/settings", {
      "nav": nav,
      "fields": fields,
    });
  }

  /// Confirmed real route + multipart shape live 2026-07-22 (OPTIONS
  /// schema) - same `file` field convention as every other BuddyBoss
  /// attachment upload already in this app (see BuddyBossService.uploadMedia).
  Future<Response> uploadGroupAvatar({required String groupId, required File file}) async {
    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last),
    });
    return _api.post("/buddyboss/v1/groups/$groupId/avatar", formData);
  }

  Future<Response> uploadGroupCover({required String groupId, required File file}) async {
    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last),
    });
    return _api.post("/buddyboss/v1/groups/$groupId/cover", formData);
  }
}
