/// A comment on an activity post. BuddyBoss represents comments as activity
/// sub-items internally, so this mirrors [Post.fromBuddyBoss]'s parsing
/// approach — the exact response shape for the comment endpoints hasn't
/// been independently captured, so field access defensively falls back
/// across the field names BuddyBoss has used for the equivalent concept
/// on the main activity object, which *is* confirmed.
class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime createdAt;
  int likeCount;
  bool isLiked;
  final bool canDelete;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
    required this.likeCount,
    required this.isLiked,
    required this.canDelete,
    List<Comment>? replies,
  }) : replies = replies ?? [];

  factory Comment.fromBuddyBoss(Map<String, dynamic> json) {
    String content = '';
    final rawContent = json['content'];
    if (rawContent is Map) {
      content = (rawContent['rendered'] ?? '').toString();
    } else if (rawContent is String) {
      content = rawContent;
    }
    content = content.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    String avatar = '';
    final avatarUrls = json['avatar_urls'] ?? json['user_avatar'];
    if (avatarUrls is Map) {
      avatar = (avatarUrls['thumb'] ?? avatarUrls['full'] ?? '').toString();
    }

    final repliesJson = json['children'] ?? json['replies'];
    final replies = repliesJson is List
        ? repliesJson
            .whereType<Map>()
            .map((r) => Comment.fromBuddyBoss(Map<String, dynamic>.from(r)))
            .toList()
        : <Comment>[];

    return Comment(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      userName: (json['name'] ?? json['user_name'] ?? 'Unknown').toString(),
      userAvatar: avatar,
      content: content,
      createdAt: DateTime.tryParse((json['date'] ?? '').toString()) ??
          DateTime.now(),
      likeCount: int.tryParse('${json['favorite_count'] ?? 0}') ?? 0,
      isLiked: json['favorited'] == true,
      canDelete: json['can_delete'] == true,
      replies: replies,
    );
  }
}
