import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String username;
  final String profession;
  final String profileImage;
  final String caption;
  final String postImage;
  final int likes;
  final int comments;
  final int shares;
  final DateTime createdAt;
  final String time;
final bool canComment;
final String activityType;
final String profileLink;
final bool isPinned;
final String privacy;
final String previewData;

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
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json["id"]?.toString() ?? "",
      userId: json["userId"]?.toString() ?? "",
      username: json["username"] ?? "",
      profession: json["profession"] ?? "",
      profileImage: json["profileImage"] ?? "",
      caption: json["caption"] ?? "",
      postImage: json["postImage"] ?? "",
      likes: json["likes"] ?? 0,
      comments: json["comments"] ?? 0,
      shares: json["shares"] ?? 0,
      createdAt: json["createdAt"] is Timestamp
          ? (json["createdAt"] as Timestamp).toDate()
          : DateTime.now(),
      time: json["time"] ?? "",
      canComment: json["canComment"] ?? false,
      activityType: json["activityType"] ?? "",
      profileLink: json["profileLink"] ?? "",
      isPinned: json["isPinned"] ?? false,
      privacy: json["privacy"] ?? "",
      previewData: json["previewData"] ?? "",  
    );
  }

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

canComment: json["can_comment"] ?? false,

activityType: json["type"] ?? "",

profileLink: json["link"] ?? "",

isPinned: json["is_pinned"] ?? false,

privacy: json["privacy"] ?? "public",

previewData: json["preview_data"]?.toString() ?? "",  
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "username": username,
      "profession": profession,
      "profileImage": profileImage,
      "caption": caption,
      "postImage": postImage,
      "likes": likes,
      "comments": comments,
      "shares": shares,
      "createdAt": Timestamp.fromDate(createdAt),
      "time": time,
      "canComment": canComment,
      "activityType": activityType,
      "profileLink": profileLink,
      "isPinned": isPinned,
      "privacy": privacy,
      "previewData": previewData,
    };
  }
}