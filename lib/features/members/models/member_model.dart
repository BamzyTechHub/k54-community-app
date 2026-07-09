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

  Member({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.lastActive,
  });

  factory Member.fromBuddyBoss(Map<String, dynamic> json) {
    return Member(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown').toString(),
      avatarUrl: (json['avatar_urls']?['thumb'] ?? json['avatar_urls']?['full'])?.toString(),
      lastActive: json['last_activity']?.toString(),
    );
  }
}
