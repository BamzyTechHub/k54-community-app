import 'package:dio/dio.dart';
import 'package:k54_mobile/core/services/api_service.dart';

/// Raw HTTP calls for the `/buddyboss/v1/friends` surface. No business
/// logic or caching here - that belongs in FriendsRepository, same
/// division of responsibility as MessagingApiService/
/// BetterMessagesApiService.
///
/// GET is wired against real, evidence-backed parameters (see
/// friendship_model.dart's doc comment for the source). The five write
/// operations below are deliberately left unimplemented: BuddyBoss's site
/// pattern for every other feature audited so far (messaging, groups,
/// members, activity) turned out to use a legacy admin-ajax.php action
/// for the website's own UI rather than this REST surface, so calling
/// these without a live capture confirming which transport - and the
/// exact request shape - the site actually uses risks silently hitting
/// the wrong system or the wrong payload shape entirely.
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

  static Never _unconfirmed(String action) {
    throw UnimplementedError(
      "$action isn't wired up yet - the live site's real transport "
      "(REST vs. a legacy admin-ajax.php action) and exact request shape "
      "for this write operation haven't been confirmed. Needs a live "
      "network capture before this can be implemented safely.",
    );
  }

  Future<Response> sendFriendRequest({
    required String initiatorId,
    required String friendId,
  }) =>
      _unconfirmed("Sending a friend request");

  Future<Response> acceptFriendRequest(String friendshipId) =>
      _unconfirmed("Accepting a friend request");

  Future<Response> rejectFriendRequest(String friendshipId) =>
      _unconfirmed("Rejecting a friend request");

  Future<Response> removeFriend(String friendshipId) =>
      _unconfirmed("Removing a friend");

  Future<Response> cancelOutgoingRequest(String friendshipId) =>
      _unconfirmed("Cancelling an outgoing friend request");
}
