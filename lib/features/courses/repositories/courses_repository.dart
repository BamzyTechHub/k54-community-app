import 'package:k54_mobile/features/courses/models/course_model.dart';
import 'package:k54_mobile/features/courses/services/courses_api_service.dart';

class CoursesRepository {
  CoursesRepository._internal();
  static final CoursesRepository instance = CoursesRepository._internal();

  final CoursesApiService _api = CoursesApiService();

  Future<({List<Course> courses, int? total})> getCourses({int page = 1, int perPage = 20, String? authorId}) async {
    final response = await _api.getCourses(page: page, perPage: perPage, authorId: authorId);
    final List raw = response.data is List ? response.data : const [];
    final courses = raw.whereType<Map>().map((c) => Course.fromWordPress(Map<String, dynamic>.from(c))).toList();
    final totalHeader = response.headers.value("x-wp-total");
    return (courses: courses, total: totalHeader != null ? int.tryParse(totalHeader) : null);
  }
}
