/// A BuddyBoss group, per BuddyPress's open-source BP-REST plugin
/// (class-bp-rest-groups-endpoint.php on github.com/buddypress/BP-REST) -
/// the same evidence-based-not-guessed approach used for friendship_model.dart.
/// BuddyBoss Platform reuses BP-REST's own endpoint classes for this
/// namespace (confirmed for Friends; the identical `buddyboss/v1/groups`
/// route shape in this project's own route-index audit corroborates the
/// same holds here).
class Group {
  final String id;
  final String name;
  final String description;
  final String status; // "public" | "private" | "hidden"
  final String? avatarUrl;
  final String? coverUrl;
  final int totalMemberCount;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.avatarUrl,
    this.coverUrl,
    required this.totalMemberCount,
  });

  factory Group.fromBuddyBoss(Map<String, dynamic> json) {
    String description = "";
    final rawDescription = json['description'];
    if (rawDescription is Map) {
      description = (rawDescription['rendered'] ?? rawDescription['raw'] ?? '').toString();
    } else if (rawDescription is String) {
      description = rawDescription;
    }

    return Group(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown group').toString(),
      description: description.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
      status: (json['status'] ?? 'public').toString(),
      avatarUrl: (json['avatar_urls']?['full'] ?? json['avatar_urls']?['thumb'])?.toString(),
      coverUrl: json['cover_url']?.toString(),
      totalMemberCount: int.tryParse('${json['total_member_count'] ?? 0}') ?? 0,
    );
  }
}
