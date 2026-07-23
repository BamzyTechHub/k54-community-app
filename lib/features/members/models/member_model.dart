/// A BuddyBoss member, as returned by the confirmed
/// `GET /buddyboss/v1/members` endpoint (the same one already proven
/// working by messaging's "New Conversation" search - see
/// docs/api-audit/members.md). Fields read here match exactly what that
/// existing, working call already relies on (`id`, `name`,
/// `avatar_urls.thumb`), plus a couple of additional fields commonly
/// present on the same response shape.
class Member {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? lastActive;

  /// Real follow state - confirmed live 2026-07-21 on this same member
  /// object shape (`is_following`/`can_follow`/`followers`/`following`),
  /// same endpoint the follow/unfollow action itself updates.
  final bool isFollowing;
  final bool canFollow;
  final int followerCount;
  final int followingCount;

  /// Real friendship state - same fields already confirmed and used on
  /// the Profile page's Connect button. Four real values confirmed live
  /// 2026-07-23: "is_friend"/"not_friends", plus a real, DISTINCT pair for
  /// pending requests depending on direction - "pending" (you sent it) vs
  /// "awaiting_response" (they sent it to you) - not the same string, so
  /// callers must handle both rather than treating all pending requests
  /// as outgoing.
  final String friendshipStatus;
  final String? friendshipId;

  Member({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.lastActive,
    this.isFollowing = false,
    this.canFollow = false,
    this.followerCount = 0,
    this.followingCount = 0,
    this.friendshipStatus = "not_friends",
    this.friendshipId,
  });

  factory Member.fromBuddyBoss(Map<String, dynamic> json) {
    return Member(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown').toString(),
      avatarUrl: (json['avatar_urls']?['thumb'] ?? json['avatar_urls']?['full'])?.toString(),
      lastActive: json['last_activity']?.toString(),
      isFollowing: json['is_following'] == true,
      canFollow: json['can_follow'] == true,
      followerCount: int.tryParse('${json['followers'] ?? 0}') ?? 0,
      followingCount: int.tryParse('${json['following'] ?? 0}') ?? 0,
      friendshipStatus: (json['friendship_status'] ?? 'not_friends').toString(),
      friendshipId: json['friendship_id']?.toString(),
    );
  }
}
