import 'package:dio/dio.dart';
import 'package:k54_mobile/core/services/api_service.dart';

class SearchApiService {
  final ApiService _api = ApiService.instance;

  Future<Response> search({required String query, int page = 1, int perPage = 20}) {
    return _api.get(
      "/wp/v2/search",
      query: {"search": query, "page": page, "per_page": perPage},
    );
  }
}
