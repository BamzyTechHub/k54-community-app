/// A BuddyBoss friendship record, hydrated with the other participant's
/// basic profile info for display.
///
/// Evidence tier: 🟡 High confidence, not a live capture. The raw
/// id/initiator_id/friend_id/is_confirmed/date_created fields are taken
/// directly from BuddyPress's open-source BP-REST plugin source
/// (class-bp-rest-friends-endpoint.php on github.com/buddypress/BP-REST)
/// and the official developer.buddypress.org REST reference, cross-checked
/// against this project's own route-index audit confirming
/// `buddyboss/v1/friends` exposes the identical GET/POST/PUT/PATCH/DELETE
/// route shape. BuddyBoss Platform is documented as reusing BP-REST's own
/// endpoint classes, so this is real source-code evidence, not a guess -
/// but it has never been exercised against the live k54global.com site,
/// so treat field names as likely-correct rather than confirmed until a
/// live GET /friends response is captured.
class Friendship {
  final String id;
  final String initiatorId;
  final String friendId;
  final bool isConfirmed;
  final DateTime? dateCreated;

  /// Whichever side of the friendship isn't the current user - hydrated
  /// from a separate GET /members/{id} call (the friendship object itself
  /// carries no embedded profile data, only the two raw user IDs).
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  /// True if the current user sent this request (relevant only while
  /// [isConfirmed] is false - determines "Cancel" vs "Accept/Reject" UI).
  final bool isOutgoing;

  Friendship({
    required this.id,
    required this.initiatorId,
    required this.friendId,
    required this.isConfirmed,
    required this.dateCreated,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.isOutgoing,
  });

  factory Friendship.fromBuddyBoss(
    Map<String, dynamic> json, {
    required String currentUserId,
    Map<String, dynamic>? otherUserProfile,
  }) {
    final initiatorId = (json['initiator_id'] ?? '').toString();
    final friendId = (json['friend_id'] ?? '').toString();
    final isOutgoing = initiatorId == currentUserId;
    final otherUserId = isOutgoing ? friendId : initiatorId;

    return Friendship(
      id: (json['id'] ?? '').toString(),
      initiatorId: initiatorId,
      friendId: friendId,
      isConfirmed: json['is_confirmed'] == true || json['is_confirmed'] == 1,
      dateCreated: DateTime.tryParse((json['date_created'] ?? '').toString()),
      otherUserId: otherUserId,
      otherUserName: (otherUserProfile?['name'] ?? 'Unknown').toString(),
      otherUserAvatar: (otherUserProfile?['avatar_urls']?['thumb'] ??
              otherUserProfile?['avatar_urls']?['full'])
          ?.toString(),
      isOutgoing: isOutgoing,
    );
  }
}
