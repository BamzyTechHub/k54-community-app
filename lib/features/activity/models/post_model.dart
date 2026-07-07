class Post {
  final String id;
  final String userId;
  final String username;
  final String profession;
  final String profileImage;
  final String caption;
  final String postImage;
  int likes;
  final int comments;
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

    return Post(
      id: json["id"].toString(),
      userId: json["user_id"]?.toString() ?? "",
      username: json["name"] ?? "Unknown User",
      profession: json["profession"] ?? "",
      profileImage: avatar,
      caption: caption,
      postImage: image,
      likes: json["favorite_count"] ?? 0,
      comments: json["comment_count"] ?? 0,
      shares: json["share_count"] ?? 0,
      createdAt:
      DateTime.tryParse(json["date"] ?? "") ?? DateTime.now(),
      time: json["date"] ?? "",
      isFavorited: json["favorited"] ?? false,
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