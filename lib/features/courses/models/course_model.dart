/// A real Tutor LMS course, from WordPress's own `courses` post type
/// (`GET /wp/v2/courses`) - confirmed live 2026-07-19 as the actual
/// course-browsing endpoint (Tutor LMS's own `tutor/v1/courses` is an
/// instructor/admin-management API, permission-gated for regular
/// members; this is the public one).
///
/// Deliberately has NO `lessons`/`duration`/`rating` fields - none of
/// those exist on this endpoint's response (confirmed by reading the
/// real object's full property list), and lesson/topic detail is still
/// blocked by the same permission wall `tutor/v1/courses` had (see
/// docs/api-audit/courses.md). Showing a fabricated number there would
/// be exactly the "static placeholder" problem this replaces - once
/// that endpoint is unblocked, this model gains those fields for real.
class Course {
  final String id;
  final String title;
  final String excerpt;
  final String contentHtml;
  final String imageUrl;
  final String link;
  final String authorName;
  final DateTime date;

  const Course({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.contentHtml,
    required this.imageUrl,
    required this.link,
    required this.authorName,
    required this.date,
  });

  factory Course.fromWordPress(Map<String, dynamic> json) {
    String stripHtml(String input) => input.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    String imageUrl = "";
    final embedded = json["_embedded"];
    if (embedded is Map) {
      final media = embedded["wp:featuredmedia"];
      if (media is List && media.isNotEmpty && media.first is Map) {
        imageUrl = (media.first["source_url"] ?? "").toString();
      }
    }

    String authorName = "";
    if (embedded is Map) {
      final authors = embedded["author"];
      if (authors is List && authors.isNotEmpty && authors.first is Map) {
        authorName = (authors.first["name"] ?? "").toString();
      }
    }

    return Course(
      id: (json["id"] ?? "").toString(),
      title: stripHtml((json["title"]?["rendered"] ?? "").toString()),
      excerpt: stripHtml((json["excerpt"]?["rendered"] ?? "").toString()),
      contentHtml: (json["content"]?["rendered"] ?? "").toString(),
      imageUrl: imageUrl,
      link: (json["link"] ?? "").toString(),
      authorName: authorName,
      date: DateTime.tryParse((json["date"] ?? "").toString()) ?? DateTime.now(),
    );
  }
}
