class Post {
  final String id;
  final String userId;
  final String username;
  final String profession;
  final String profileImage;
  final String caption;
  final String postImage;
  int likes;
  int comments;
  int shares;
  final DateTime createdAt;
  final String time;
final bool canComment;
final String activityType;
final String profileLink;
bool isPinned;
final String privacy;
final String previewData;
bool isFavorited;
  /// The reaction type id (635=Like, 636=Love, 637=Laugh, 638=Angry,
  /// 639=Sad, 640=Wow) the current user gave via the real BuddyBoss
  /// reactions system, or 0 if none. Confirmed live on `reacted_id` in the
  /// activity endpoint's schema 2026-07-17 - a separate, richer system
  /// from the older favorite/unfavorite boolean above.
  int reactedId;
final bool canEdit;
final bool canDelete;
  /// No confirmed server field distinguishes "owner closed comments on
  /// this post" from the general can_comment permission, so this is
  /// purely local session state, set only after the user actually taps
  /// the close/open-comments toggle — it will not reflect a closure that
  /// happened in a previous session until the real field is identified.
  bool commentsClosed;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.profession,
    required this.profileImage,
    required this.caption,
    required this.postImage,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.createdAt,
    required this.time,
    required this.canComment,
    required this.activityType,
    required this.profileLink,
    required this.isPinned,
    required this.privacy,
    required this.previewData,
    required this.isFavorited,
    this.reactedId = 0,
    required this.canEdit,
    required this.canDelete,
    this.commentsClosed = false,
  });

  factory Post.fromBuddyBoss(Map<String, dynamic> json) {
    String caption = "";

    if (json["content"] is Map) {
      caption = json["content"]["rendered"] ?? "";
      caption = caption
    .replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', dotAll: true),
      "",
    )
    .replaceAll(
      RegExp(r'<style[^>]*>.*?</style>', dotAll: true),
      "",
    );
    } else if (json["content"] is String) {
      caption = json["content"];
    }

    String avatar = "";

    if (json["avatar_urls"] != null) {
      avatar =
          json["avatar_urls"]["thumb"] ??
          json["avatar_urls"]["full"] ??
          "";
    }

    String image = "";

if (json["feature_media"] is String &&
    json["feature_media"].isNotEmpty) {
  image = json["feature_media"];
}

if (image.isEmpty &&
    json["activity_data"]?["bb_activity_post_feature_image"]?["image"] !=
        null) {
  image = json["activity_data"]["bb_activity_post_feature_image"]["image"];
}

    // `reacted_counts` is confirmed to exist on the live activity schema
    // (type: array) but its exact per-entry shape wasn't captured against
    // a real authenticated response, so this parses defensively across
    // the field names a count entry would plausibly use and falls back to
    // the older, confirmed `favorite_count` if nothing parses - never
    // silently shows 0 just because this richer field's shape guess was
    // wrong.
    int reactionTotal = 0;
    final rawCounts = json["reacted_counts"];
    if (rawCounts is List) {
      for (final entry in rawCounts) {
        if (entry is Map) {
          final c = entry["count"] ?? entry["total"] ?? entry["reaction_count"];
          reactionTotal += int.tryParse('$c') ?? 0;
        } else if (entry is num) {
          reactionTotal += entry.toInt();
        }
      }
    }
    final favoriteCount = int.tryParse('${json["favorite_count"] ?? 0}') ?? 0;

    return Post(
      id: json["id"].toString(),
      userId: json["user_id"]?.toString() ?? "",
      username: json["name"] ?? "Unknown User",
      profession: json["profession"] ?? "",
      profileImage: avatar,
      caption: caption,
      postImage: image,
      likes: reactionTotal > 0 ? reactionTotal : favoriteCount,
      comments: json["comment_count"] ?? 0,
      shares: json["share_count"] ?? 0,
      createdAt:
      DateTime.tryParse(json["date"] ?? "") ?? DateTime.now(),
      time: json["date"] ?? "",
      isFavorited: json["favorited"] ?? false,
      reactedId: int.tryParse('${json["reacted_id"] ?? 0}') ?? 0,
      canEdit: json["can_edit"] ?? false,
      canDelete: json["can_delete"] ?? false,

canComment: json["can_comment"] ?? false,

activityType: json["type"] ?? "",

profileLink: "https://k54global.com/members/${json["user_id"]}",

isPinned: json["is_pinned"] ?? false,

privacy: json["privacy"] ?? "public",

previewData: json["preview_data"]?.toString() ?? "", 

    );
  }

}