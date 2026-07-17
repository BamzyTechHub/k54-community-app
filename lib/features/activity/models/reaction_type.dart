/// The default "Like" reaction's id - confirmed live 2026-07-17 (see
/// [ReactionType] doc). Used as the plain-tap default across the app so
/// callers don't hardcode the magic number 635 in more than one place.
const int kLikeReactionId = 635;

/// One of the reaction choices from the confirmed, live `GET
/// /buddyboss/v1/reactions` endpoint (verified against k54global.com
/// 2026-07-17: id 635 "thumbs-up"/Like, 636 Love, 637 Laugh, 638 Angry,
/// 639 Sad, 640 Wow). This is BuddyBoss Platform's real reaction system,
/// separate from the older plain favorite/unfavorite boolean - not an
/// invented feature.
class ReactionType {
  final int id;
  final String name;
  final String iconText;
  final String icon;
  final String iconColor;
  final String iconPath;

  const ReactionType({
    required this.id,
    required this.name,
    required this.iconText,
    required this.icon,
    required this.iconColor,
    required this.iconPath,
  });

  /// The built-in "Like" entry has no remote icon_path (it's rendered as a
  /// plain glyph); the other five are twemoji SVGs fetched from icon_path.
  bool get isPlainLike => iconPath.isEmpty;

  factory ReactionType.fromJson(Map<String, dynamic> json) {
    return ReactionType(
      id: int.tryParse('${json["id"] ?? 0}') ?? 0,
      name: (json["name"] ?? "").toString(),
      iconText: (json["icon_text"] ?? "").toString(),
      icon: (json["icon"] ?? "").toString(),
      iconColor: (json["icon_color"] ?? "").toString(),
      iconPath: (json["icon_path"] ?? "").toString(),
    );
  }
}
