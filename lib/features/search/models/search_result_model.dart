/// Maps WordPress core's `GET /wp/v2/search` response - confirmed live
/// against k54global.com (id/title/url/type/subtype), the same endpoint
/// the website's own search page uses, which is a plain flat list with
/// no filters or tabs (verified against the live site's own search UI).
class SearchResult {
  final int id;
  final String title;
  final String url;
  final String type;
  final String subtype;

  SearchResult({
    required this.id,
    required this.title,
    required this.url,
    required this.type,
    required this.subtype,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      title: (json['title'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      subtype: (json['subtype'] ?? '').toString(),
    );
  }
}
