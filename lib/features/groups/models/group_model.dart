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

  /// Real per-user membership state, directly embedded on every group in
  /// the list response (confirmed live 2026-07-20 - the earlier doc
  /// comment on GroupsPage claiming "no confirmed field identifies the
  /// current user's role" was wrong, or true only for whatever capture it
  /// was written against; this endpoint returns all of it today).
  final bool isMember;
  final bool isAdmin;
  final bool isMod;
  final String role; // "", "Member", "Moderator", "Organizer"

  /// Whether the current user can directly join (public group, not
  /// already a member/pending). For a private group this is `false` even
  /// when not yet a member - joining there goes through
  /// `groups/membership-requests` instead of `groups/{id}/members`.
  final bool canJoin;

  /// A truthy id when this user has an open, unresolved join request on a
  /// private group (`false` from the API when none exists) - confirmed
  /// real route: `buddyboss/v1/groups/membership-requests`. Not yet
  /// observed in a real pending state (every group on this site is
  /// currently "public"), but the field and route are both confirmed to
  /// exist from the live route index's arg schema.
  final String? requestId;

  /// Whether this group's bbPress-style forum (Discussions) is enabled,
  /// and its real numeric forum id when it is - confirmed live 2026-07-22
  /// on the group object (`enable_forum` bool + `forum` int, 0 when
  /// disabled). Needed to fetch this group's own discussion topics via
  /// `GET /buddyboss/v1/topics?parent={forumId}`.
  final bool enableForum;
  final String? forumId;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.avatarUrl,
    this.coverUrl,
    required this.totalMemberCount,
    this.isMember = false,
    this.isAdmin = false,
    this.isMod = false,
    this.role = "",
    this.canJoin = true,
    this.requestId,
    this.enableForum = false,
    this.forumId,
  });

  bool get isPrivate => status == "private";
  bool get hasPendingRequest => requestId != null && requestId != "false" && requestId!.isNotEmpty;

  factory Group.fromBuddyBoss(Map<String, dynamic> json) {
    String description = "";
    final rawDescription = json['description'];
    if (rawDescription is Map) {
      description = (rawDescription['rendered'] ?? rawDescription['raw'] ?? '').toString();
    } else if (rawDescription is String) {
      description = rawDescription;
    }

    // `request_id`/`invite_id` come back as the literal boolean `false`
    // when absent, or a numeric id when present - never a plain "no
    // value" (null/missing key), per the live response shape.
    final rawRequestId = json['request_id'];
    final requestId = (rawRequestId == false || rawRequestId == null) ? null : rawRequestId.toString();

    return Group(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown group').toString(),
      description: description.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
      status: (json['status'] ?? 'public').toString(),
      avatarUrl: (json['avatar_urls']?['full'] ?? json['avatar_urls']?['thumb'])?.toString(),
      coverUrl: json['cover_url']?.toString(),
      // Real field is `members_count` (a numeric string, e.g. "6") -
      // `total_member_count` doesn't exist on this endpoint at all,
      // confirmed live 2026-07-21 - every group card was showing "0
      // members" because of this, not because of a real zero-member group.
      totalMemberCount: int.tryParse('${json['members_count'] ?? 0}') ?? 0,
      isMember: json['is_member'] == true,
      isAdmin: json['is_admin'] == true,
      isMod: json['is_mod'] == true,
      role: (json['role'] ?? '').toString(),
      canJoin: json['can_join'] == true,
      requestId: requestId,
      enableForum: json['enable_forum'] == true,
      forumId: (json['forum'] != null && json['forum'].toString() != '0') ? json['forum'].toString() : null,
    );
  }
}
