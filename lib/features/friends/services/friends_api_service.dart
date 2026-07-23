import 'package:dio/dio.dart';
import 'package:k54_mobile/core/services/api_service.dart';

/// Raw HTTP calls for the `/buddyboss/v1/friends` surface. No business
/// logic or caching here - that belongs in FriendsRepository, same
/// division of responsibility as MessagingApiService/
/// BetterMessagesApiService.
///
/// GET is wired against real, evidence-backed parameters (see
/// friendship_model.dart's doc comment for the source). A 2026-07-14 HAR
/// capture showed the live site's own UI actually calls a legacy
/// admin-ajax.php action (`friends_add_friend`/`friends_remove_friend`)
/// for these writes, secured with a WordPress nonce that only exists
/// embedded in an authenticated page render - something this JWT-only
/// app has no way to obtain. However, the same capture's public
/// `/wp-json/` route index confirms real REST alternatives are
/// registered: `POST/DELETE /buddyboss/v1/friends` and
/// `GET/POST/PUT/PATCH/DELETE /buddyboss/v1/friends/{id}` (standard
/// BP-REST plugin shape, same source already cited for GET). The
/// **field names below are BP-REST's typical convention, not directly
/// captured** - confirmed live by the user testing, not guessed blind,
/// but treat any error response's message as more authoritative than
/// this comment if they disagree.
class FriendsApiService {
  final ApiService _api = ApiService.instance;

  /// [isConfirmed] filters to accepted friendships (1) or pending
  /// requests (0); omit for both. `user_id` defaults server-side to the
  /// logged-in user if omitted, per the BP-REST source, but this always
  /// passes it explicitly to avoid relying on that default silently.
  Future<Response> getFriendships({
    required String userId,
    int? isConfirmed,
    int page = 1,
    int perPage = 20,
  }) {
    return _api.get(
      "/buddyboss/v1/friends",
      query: {
        "user_id": userId,
        "page": page,
        "per_page": perPage,
        "is_confirmed": ?isConfirmed,
      },
    );
  }

  /// Sends a friend request. `initiator_id` matches the pattern already
  /// confirmed for GET (see getFriendships) - BP-REST infers the
  /// initiator from the authenticated user server-side regardless, this
  /// is sent explicitly for the same "don't rely on a silent default"
  /// reason getFriendships does.
  Future<Response> sendFriendRequest({
    required String initiatorId,
    required String friendId,
  }) {
    return _api.post("/buddyboss/v1/friends", {
      "initiator_id": initiatorId,
      "friend_id": friendId,
    });
  }

  /// BP-REST's friendship resource uses `PUT` with an explicit `action`
  /// disambiguating accept-vs-otherwise on the same status code path.
  Future<Response> acceptFriendRequest(String friendshipId) {
    return _api.put("/buddyboss/v1/friends/$friendshipId", {"action": "accept_friendship"});
  }

  Future<Response> rejectFriendRequest(String friendshipId) {
    return _api.delete("/buddyboss/v1/friends/$friendshipId");
  }

  /// Confirmed live 2026-07-24: BuddyBoss's own `DELETE
  /// /buddyboss/v1/friends/{id}` reliably 500s specifically for an
  /// already-CONFIRMED friendship (a real bug in their REST controller,
  /// not BuddyPress core - the underlying `friends_remove_friend()`
  /// function works perfectly when called directly, which is exactly
  /// what this custom bridge route does, matching the real website's own
  /// behavior confirmed via an earlier HAR capture: the site's own UI
  /// also avoids this REST endpoint for remove and calls the same legacy
  /// function). See docs/api-audit/k54-friends-remove-debug.php.
  Future<Response> removeFriend(String friendshipId) {
    return _api.post("/k54-friends/v1/remove", {"friendship_id": friendshipId});
  }

  Future<Response> cancelOutgoingRequest(String friendshipId) {
    return _api.delete("/buddyboss/v1/friends/$friendshipId");
  }

  /// Real REST avatar upload, confirmed registered (not directly
  /// captured with a request body) at `POST /members/{id}/avatar`.
  /// BP-REST's avatar endpoint expects a multipart file field.
  Future<Response> uploadAvatar({required String userId, required List<int> fileBytes, required String filename}) {
    final formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(fileBytes, filename: filename),
    });
    return _api.post("/buddyboss/v1/members/$userId/avatar", formData);
  }

  Future<Response> deleteAvatar(String userId) {
    return _api.delete("/buddyboss/v1/members/$userId/avatar");
  }
}
