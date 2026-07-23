/// A photo attached via BuddyBoss's own media/gallery mechanism
/// (`bp_media_ids` on the activity object) - confirmed real via a live
/// authenticated sample 2026-07-19, a separate mechanism from the
/// featured-image field (`feature_media`) already parsed above.
class PostPhoto {
  final String imageUrl;
  final String title;

  const PostPhoto({required this.imageUrl, required this.title});

  factory PostPhoto.fromJson(Map<String, dynamic> json) {
    final data = json["attachment_data"];
    String url = "";
    if (data is Map) {
      url = (data["activity_thumb"] ?? data["full"] ?? data["thumb"] ?? "").toString();
    }
    return PostPhoto(imageUrl: url, title: (json["title"] ?? "").toString());
  }
}

/// A document attached via BuddyBoss's documents feature (`bp_documents`)
/// - confirmed real 2026-07-19. `previewUrl` is a thumbnail image of the
/// document, not the document itself - the real file is at [downloadUrl].
class PostDocument {
  final String filename;
  final String extension;
  final String size;
  final String downloadUrl;
  final String previewUrl;

  const PostDocument({
    required this.filename,
    required this.extension,
    required this.size,
    required this.downloadUrl,
    required this.previewUrl,
  });

  factory PostDocument.fromJson(Map<String, dynamic> json) {
    final data = json["attachment_data"];
    String preview = "";
    if (data is Map) {
      preview = (data["activity_thumb"] ?? data["thumb"] ?? "").toString();
    }
    return PostDocument(
      filename: (json["filename"] ?? json["title"] ?? "Document").toString(),
      extension: (json["extension"] ?? "").toString(),
      size: (json["size"] ?? "").toString(),
      downloadUrl: (json["download_url"] ?? "").toString(),
      previewUrl: preview,
    );
  }
}

/// A video attached via BuddyBoss's video feature (`bp_videos`) - confirmed
/// real 2026-07-19. [videoUrl] (the `bb-video-preview/...` link) was
/// directly tested with a real authenticated request and returns a real
/// `video/mp4` stream - a native video player can play it directly,
/// passing the same Authorization bearer header the app already attaches
/// to every other request via ApiService's shared Dio instance.
class PostVideo {
  final String videoUrl;
  final String posterUrl;
  final String durationLabel;

  const PostVideo({required this.videoUrl, required this.posterUrl, required this.durationLabel});

  factory PostVideo.fromJson(Map<String, dynamic> json) {
    final data = json["attachment_data"];
    String duration = "";
    if (data is Map && data["meta"] is Map) {
      duration = (data["meta"]["length_formatted"] ?? "").toString();
    }
    return PostVideo(
      videoUrl: (json["url"] ?? "").toString(),
      posterUrl: (json["video_activity_thumb"] ?? (data is Map ? data["full"] : null) ?? "").toString(),
      durationLabel: duration,
    );
  }
}

/// Parses a BuddyBoss attachment field (`bp_media_ids`/`bp_videos`/
/// `bp_documents`) into a list - every real sample seen so far has been a
/// single object, not an array, but this handles both shapes defensively
/// since a genuine multi-photo gallery post is plausible and unconfirmed
/// either way.
List<Map<String, dynamic>> _parseAttachmentField(dynamic raw) {
  if (raw is Map && raw.isNotEmpty) return [Map<String, dynamic>.from(raw)];
  if (raw is List) return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  return const [];
}

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
  // Real BuddyBoss attachment mechanisms (bp_media_ids/bp_videos/
  // bp_documents) - separate from postImage (the featured-image field).
  // Every real sample seen has one of each at most, but these are lists
  // since the field can technically hold more than one - see
  // _parseAttachmentField's doc comment.
  final List<PostPhoto> photos;
  final List<PostVideo> videos;
  final List<PostDocument> documents;
  /// The real bbPress topic/reply id this activity is about - confirmed
  /// live 2026-07-22 as `secondary_item_id`, only meaningful when
  /// [activityType] is "bbp_topic_create" (a new discussion - the id IS
  /// the topic id directly) or "bbp_reply_create" (a reply - the id is
  /// the reply's own post id, whose `parent` field is the topic id).
  /// Lets a group's Feed tab render a real "Join Discussion" link instead
  /// of just a static activity notice, matching the real site.
  final String? discussionId;

  /// True when this activity is WPStream's own "I'm live" post - confirmed
  /// live 2026-07-22 by a real captured sample: when a user goes live,
  /// WPStream inserts a plain `activity_update` whose `content.rendered` is
  /// a fixed template containing a `wpstream_player_wrapper` div (an empty
  /// shell only WPStream's own site JS knows how to fill with an iframe -
  /// which is exactly why this rendered as a blank/static box in the app
  /// before: nothing was there to fill it). [userId] is the broadcaster to
  /// resolve a real channel id from (via LiveVideoRepository), which is
  /// then used to fetch the real playback status/HLS url.
  final bool isLiveStreamActivity;

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
    this.photos = const [],
    this.videos = const [],
    this.documents = const [],
    this.discussionId,
    this.isLiveStreamActivity = false,
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

    // Confirmed live 2026-07-22 - see [isLiveStreamActivity]'s doc comment.
    // The marker divs are stripped out here (rather than left for the Html
    // widget to render, which would just show blank boxes) since PostCard
    // renders its own real "LIVE" card in their place instead.
    final isLiveStreamActivity = caption.contains('wpstream_player_wrapper');
    if (isLiveStreamActivity) {
      caption = caption
          .replaceAll(RegExp(r'<div class="wpstreaam_bb_see_mee_live">.*?</div>', dotAll: true), "")
          .replaceAll(
            RegExp(
              r'<div class="wpstream_insert_player_elementor_wrapper">.*?</div>\s*</div>\s*</div>\s*</div>',
              dotAll: true,
            ),
            "",
          )
          .trim();
    }

    // For every activity type other than a real text post
    // ("activity_update"), `content.rendered` comes back genuinely empty -
    // confirmed live 2026-07-20 across joined_group/new_member/
    // friendship_created/updated_profile/new_avatar. The real human-
    // readable sentence ("X joined the group Y", "X became a registered
    // member", ...) lives on `title` instead (HTML with real profile/group
    // links), which the app was never reading at all - this is exactly why
    // the home feed showed only the avatar/username with nothing else for
    // these activity types. `title` is always populated even for a real
    // post ("X posted an update"), so this only falls back to it when
    // content is genuinely empty rather than always preferring it.
    if (caption.replaceAll(RegExp(r'<[^>]*>'), '').trim().isEmpty) {
      final title = json["title"];
      if (title is String && title.isNotEmpty) {
        caption = title;
      }
    }

    // The real field on this endpoint is `user_avatar` (confirmed live
    // 2026-07-19 via the activity schema: "Avatar URLs for the author of
    // the activity") - `avatar_urls` doesn't exist here at all, which is
    // why every post fell back to the initial-letter placeholder no
    // matter who posted.
    String avatar = "";
    final avatarUrls = json["user_avatar"] ?? json["avatar_urls"];
    if (avatarUrls is Map) {
      avatar = (avatarUrls["thumb"] ?? avatarUrls["full"] ?? "").toString();
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
      photos: _parseAttachmentField(json["bp_media_ids"]).map((m) => PostPhoto.fromJson(m)).toList(),
      videos: _parseAttachmentField(json["bp_videos"]).map((m) => PostVideo.fromJson(m)).toList(),
      documents: _parseAttachmentField(json["bp_documents"]).map((m) => PostDocument.fromJson(m)).toList(),
      createdAt:
      DateTime.tryParse(json["date"] ?? "") ?? DateTime.now(),
      time: json["date"] ?? "",
      isFavorited: json["favorited"] ?? false,
      reactedId: int.tryParse('${json["reacted_id"] ?? 0}') ?? 0,
      canEdit: json["can_edit"] ?? false,
      canDelete: json["can_delete"] ?? false,

canComment: json["can_comment"] ?? false,

activityType: json["type"] ?? "",

discussionId: (json["type"] == "bbp_topic_create" || json["type"] == "bbp_reply_create")
    ? json["secondary_item_id"]?.toString()
    : null,

profileLink: "https://k54global.com/members/${json["user_id"]}",

isPinned: json["is_pinned"] ?? false,

privacy: json["privacy"] ?? "public",

previewData: json["preview_data"]?.toString() ?? "",

isLiveStreamActivity: isLiveStreamActivity,

    );
  }

}