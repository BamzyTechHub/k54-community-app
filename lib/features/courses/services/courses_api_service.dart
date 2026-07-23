import 'package:dio/dio.dart';
import 'package:k54_mobile/core/services/api_service.dart';

/// Real course-catalog endpoint - `GET /wp/v2/courses`, WordPress's own
/// standard post-type REST route for Tutor LMS's "courses" post type.
/// Confirmed live 2026-07-19: works with the app's existing JWT, no
/// separate auth needed (unlike `tutor/v1/courses`, which is instructor/
/// admin-only and 403s for a regular member).
class CoursesApiService {
  final ApiService _api = ApiService.instance;

  /// [authorId] filters to only that user's own authored courses -
  /// standard WordPress core REST behavior for any public post type
  /// (`?author={id}`), confirmed live 2026-07-21 against this exact
  /// endpoint (course 791 "K54 Global Growth Program", author 5,
  /// correctly returned only for `?author=5` and correctly excluded for
  /// a non-matching author id).
  Future<Response> getCourses({int page = 1, int perPage = 20, String? authorId}) {
    return _api.get(
      "/wp/v2/courses",
      query: {
        "page": page,
        "per_page": perPage,
        "_embed": 1,
        "author": ?authorId,
      },
    );
  }
}
