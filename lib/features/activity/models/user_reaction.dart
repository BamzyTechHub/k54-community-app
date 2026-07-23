/// A single reaction row from `/buddyboss/v1/user-reactions` - [id] is the
/// row's own id, required to DELETE it (the endpoint takes the row id, not
/// the item id or reaction type id).
class UserReaction {
  final int id;
  final int reactionId;
  final String itemType;
  final String itemId;

  const UserReaction({
    required this.id,
    required this.reactionId,
    required this.itemType,
    required this.itemId,
  });

  factory UserReaction.fromJson(Map<String, dynamic> json) {
    return UserReaction(
      // WordPress/BuddyBoss objects often expose a row's own primary key as
      // "ID" (capital, the WP core convention for posts/users/comments)
      // rather than "id" - checking both defensively rather than assuming
      // lowercase, the same precedent already found for group admin
      // objects earlier in this project. Silently defaulting to 0 here
      // (this field's old behavior) sent every un-like's DELETE to
      // `/user-reactions/0`, which the server correctly 404s - a
      // guaranteed failure, not an occasional one, matching the reported
      // "tap like again does nothing but error" bug.
      id: int.tryParse('${json["id"] ?? json["ID"] ?? 0}') ?? 0,
      reactionId: int.tryParse('${json["reaction_id"] ?? 0}') ?? 0,
      itemType: (json["item_type"] ?? "").toString(),
      itemId: (json["item_id"] ?? "").toString(),
    );
  }
}
