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
      id: int.tryParse('${json["id"] ?? 0}') ?? 0,
      reactionId: int.tryParse('${json["reaction_id"] ?? 0}') ?? 0,
      itemType: (json["item_type"] ?? "").toString(),
      itemId: (json["item_id"] ?? "").toString(),
    );
  }
}
