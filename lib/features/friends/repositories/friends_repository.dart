import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/features/friends/models/friendship_model.dart';
import 'package:k54_mobile/features/friends/services/friends_api_service.dart';

/// Single source of truth for friends data, mirroring
/// MessagingRepository's role for messaging: one place that knows how to
/// fetch/hydrate/cache friendships, so screens never call
/// FriendsApiService directly.
class FriendsRepository {
  FriendsRepository._internal();
  static final FriendsRepository instance = FriendsRepository._internal();

  final FriendsApiService _api = FriendsApiService();
  final AuthService _authService = AuthService();

  String? _cachedUserId;

  Future<String> currentUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;
    final response = await _authService.getCurrentUser();
    _cachedUserId = (response.data['id'] ?? '').toString();
    return _cachedUserId!;
  }

  /// Hydrates each friendship with the other participant's name/avatar.
  /// The friendship object itself only carries raw user IDs (see
  /// friendship_model.dart) - this is an N+1 lookup against the confirmed
  /// working GET /members/{id} endpoint, run in parallel. No bulk
  /// "fetch several members by id" call is confirmed to exist, so this
  /// doesn't guess at one.
  Future<List<Friendship>> _hydrate(List raw, String currentUserId) async {
    final futures = raw.whereType<Map>().map((f) async {
      final json = Map<String, dynamic>.from(f);
      final initiatorId = (json['initiator_id'] ?? '').toString();
      final friendId = (json['friend_id'] ?? '').toString();
      final otherId = initiatorId == currentUserId ? friendId : initiatorId;

      Map<String, dynamic>? profile;
      try {
        final response = await _authService.getMember(otherId);
        profile = Map<String, dynamic>.from(response.data);
      } catch (_) {
        // One member lookup failing shouldn't blank out the whole list -
        // Friendship.fromBuddyBoss falls back to "Unknown" when profile
        // is null.
      }

      return Friendship.fromBuddyBoss(
        json,
        currentUserId: currentUserId,
        otherUserProfile: profile,
      );
    });

    return Future.wait(futures);
  }

  /// Confirmed (accepted) friendships only.
  Future<List<Friendship>> getFriends({int page = 1, int perPage = 20}) async {
    final userId = await currentUserId();
    final response = await _api.getFriendships(
      userId: userId,
      isConfirmed: 1,
      page: page,
      perPage: perPage,
    );
    final List raw = response.data is List ? response.data : const [];
    return _hydrate(raw, userId);
  }

  /// All pending (unconfirmed) friendships involving the current user,
  /// split client-side into incoming (someone else requested me) and
  /// outgoing (I requested someone else) - the API itself doesn't
  /// distinguish direction beyond the raw initiator_id/friend_id pair.
  Future<({List<Friendship> incoming, List<Friendship> outgoing})>
      getPendingRequests({int page = 1, int perPage = 20}) async {
    final userId = await currentUserId();
    final response = await _api.getFriendships(
      userId: userId,
      isConfirmed: 0,
      page: page,
      perPage: perPage,
    );
    final List raw = response.data is List ? response.data : const [];
    final hydrated = await _hydrate(raw, userId);

    return (
      incoming: hydrated.where((f) => !f.isOutgoing).toList(),
      outgoing: hydrated.where((f) => f.isOutgoing).toList(),
    );
  }

  Future<void> sendFriendRequest(String otherUserId) async {
    final userId = await currentUserId();
    await _api.sendFriendRequest(initiatorId: userId, friendId: otherUserId);
  }

  Future<void> acceptRequest(String friendshipId) =>
      _api.acceptFriendRequest(friendshipId);

  Future<void> rejectRequest(String friendshipId) =>
      _api.rejectFriendRequest(friendshipId);

  Future<void> removeFriend(String friendshipId) =>
      _api.removeFriend(friendshipId);

  Future<void> cancelOutgoingRequest(String friendshipId) =>
      _api.cancelOutgoingRequest(friendshipId);

  Future<void> uploadAvatar({required List<int> fileBytes, required String filename}) async {
    final userId = await currentUserId();
    await _api.uploadAvatar(userId: userId, fileBytes: fileBytes, filename: filename);
  }

  Future<void> deleteAvatar() async {
    final userId = await currentUserId();
    await _api.deleteAvatar(userId);
  }
}
