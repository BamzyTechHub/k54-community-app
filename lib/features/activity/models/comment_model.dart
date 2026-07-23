/// A comment on an activity post. BuddyBoss represents comments as activity
/// sub-items internally, so this mirrors [Post.fromBuddyBoss]'s parsing
/// approach. Response shape confirmed live 2026-07-23 via a disposable
/// test comment - both the list and create endpoints return the same
/// shape as a real activity item (`name`, `content.rendered`,
/// `content_stripped`, `user_avatar`, etc.), wrapped in
/// `{comment_count, level_comment_count, comments: [...]}`.
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
    // `content_stripped` is confirmed live 2026-07-23 to already be real,
    // decoded plain text (actual emoji characters, not the HTML numeric
    // character references `content.rendered` uses, e.g. `&#x1f600;`) -
    // preferred over manually stripping tags from `content.rendered`,
    // which left those entity codes showing as literal text in the UI.
    String content = (json['content_stripped'] ?? '').toString();
    if (content.isEmpty) {
      final rawContent = json['content'];
      if (rawContent is Map) {
        content = (rawContent['rendered'] ?? '').toString();
      } else if (rawContent is String) {
        content = rawContent;
      }
      content = content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    }

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
