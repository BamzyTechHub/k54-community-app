import 'package:k54_mobile/features/search/models/search_result_model.dart';
import 'package:k54_mobile/features/search/services/search_api_service.dart';

class SearchRepository {
  SearchRepository._internal();
  static final SearchRepository instance = SearchRepository._internal();

  final SearchApiService _api = SearchApiService();

  Future<List<SearchResult>> search({required String query, int page = 1, int perPage = 20}) async {
    final response = await _api.search(query: query, page: page, perPage: perPage);
    final List raw = response.data is List ? response.data : const [];
    return raw
        .whereType<Map>()
        .map((r) => SearchResult.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }
}
