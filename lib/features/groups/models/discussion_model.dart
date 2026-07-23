/// A group photo album - confirmed live 2026-07-22 against a real group
/// album (`GET /buddyboss/v1/media/albums?group_id={id}`). `media.medias`
/// (when embedded via the single-album fetch) is the exact same
/// `attachment_data`-shaped structure as a group's flat media list, so
/// PostPhoto.fromJson already parses each entry directly.
class GroupAlbum {
  final String id;
  final String title;
  final int mediaCount;

  const GroupAlbum({required this.id, required this.title, required this.mediaCount});

  factory GroupAlbum.fromJson(Map<String, dynamic> json) {
    final media = json['media'];
    final total = media is Map ? media['total_media'] ?? media['total'] : json['total_media'];
    return GroupAlbum(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled album').toString(),
      mediaCount: int.tryParse('${total ?? 0}') ?? 0,
    );
  }
}

/// A group's discussion topic (bbPress "topic"), confirmed live 2026-07-22
/// against a real group forum (`GET /buddyboss/v1/topics?parent={forumId}`).
class Topic {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final DateTime? date;
  final int replyCount;

  const Topic({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.date,
    required this.replyCount,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: (json['id'] ?? '').toString(),
      title: (json['title']?['rendered'] ?? '').toString(),
      content: (json['content']?['rendered'] ?? '').toString(),
      authorId: (json['author'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString()),
      replyCount: int.tryParse('${json['total_reply_count'] ?? 0}') ?? 0,
    );
  }
}

/// A reply to a discussion topic (bbPress "reply") - confirmed live
/// 2026-07-22 (`GET /buddyboss/v1/reply?parent={topicId}`).
class TopicReply {
  final String id;
  final String content;
  final String authorId;
  final DateTime? date;

  const TopicReply({
    required this.id,
    required this.content,
    required this.authorId,
    required this.date,
  });

  factory TopicReply.fromJson(Map<String, dynamic> json) {
    return TopicReply(
      id: (json['id'] ?? '').toString(),
      content: (json['content']?['rendered'] ?? '').toString(),
      authorId: (json['author'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString()),
    );
  }
}
