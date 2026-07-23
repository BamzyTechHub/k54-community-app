import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/responsive.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/core/widgets/filter_popover.dart';
import 'package:k54_mobile/core/widgets/skeleton_loaders.dart';
import 'package:k54_mobile/core/widgets/state_views.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/features/courses/models/course_model.dart';
import 'package:k54_mobile/features/courses/repositories/courses_repository.dart';

/// Wired to the real course catalog (`GET /wp/v2/courses`, confirmed live
/// 2026-07-19 - see docs/api-audit/courses.md). "Start Learning" opens the
/// real course page externally rather than "coming soon" - there's no
/// in-app lesson/quiz viewer yet (lesson/topic detail is still blocked by
/// a permission wall on `tutor/v1/topics`), but the course's own real
/// page genuinely works, so that's a real action instead of a dead one.
/// No rating stars or lesson-count/duration row - neither field exists
/// on this endpoint (confirmed by reading the real response), showing a
/// fabricated number there would be the exact "static placeholder"
/// problem this replaces. Once the lesson/topic endpoint is unblocked,
/// those can come back for real.
class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final CoursesRepository _repo = CoursesRepository.instance;

  List<Course>? _courses;
  bool _loading = true;
  Object? _error;

  String selectedFilter = "Title (A-Z)";
  final LayerLink _filterLayerLink = LayerLink();

  static const _filters = ["Title (A-Z)", "Title (Z-A)", "Newest First", "Oldest First"];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.getCourses(perPage: 50);
      if (!mounted) return;
      setState(() {
        _courses = result.courses;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  List<Course> get _sortedCourses {
    final courses = <Course>[...?_courses];
    switch (selectedFilter) {
      case "Title (Z-A)":
        courses.sort((a, b) => b.title.compareTo(a.title));
        break;
      case "Newest First":
        courses.sort((a, b) => b.date.compareTo(a.date));
        break;
      case "Oldest First":
        courses.sort((a, b) => a.date.compareTo(b.date));
        break;
      default: // Title (A-Z)
        courses.sort((a, b) => a.title.compareTo(b.title));
    }
    return courses;
  }

  void _openFilterPopover() {
    showFilterPopover(
      context: context,
      layerLink: _filterLayerLink,
      sections: [
        FilterSection(
          label: "Course Filter",
          options: _filters
              .map((label) => FilterOption(
                    label: label,
                    selected: selectedFilter == label,
                    onTap: () => setState(() => selectedFilter = label),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Future<void> _openCourse(Course course) async {
    if (course.link.isEmpty) return;
    await launchUrl(Uri.parse(course.link), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                children: [
                  // No back arrow - Courses is a main bottom-nav
                  // destination (reached via pushReplacement, same as AI
                  // Assistant/Members/Groups/Home), not a pushed screen.
                  const Text("Courses", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  CompositedTransformTarget(
                    link: _filterLayerLink,
                    child: TapScale(
                      onTap: _openFilterPopover,
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.groupCardAccent),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(selectedFilter, style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 15),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const K54BottomNavigation(currentIndex: 4),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return SkeletonCardGrid(crossAxisCount: Responsive.gridColumns(context));
    }
    if (_error != null) {
      return K54ErrorState(message: "Couldn't load courses.\n$_error", onRetry: _load);
    }
    final courses = _sortedCourses;
    if (courses.isEmpty) {
      return const K54EmptyState(icon: Icons.school_outlined, message: "No courses yet");
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _load,
      child: GridView.builder(
        itemCount: courses.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.gridColumns(context),
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) {
          final course = courses[index];
          return FadeSlideIn(
            key: ValueKey(course.id),
            delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
            child: _courseCard(course),
          );
        },
      ),
    );
  }

  Widget _courseCard(Course course) {
    return TapScale(
      onTap: () => _openCourse(course),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8EFE8),
          // Radius 24 and image height 65 - exact match from node
          // 157:25's course card ("Frame 2147228245"), pulled via the
          // REST API 2026-07-16.
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              child: course.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: course.imageUrl,
                      height: 65,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(height: 65, color: AppColors.greyShade200),
                      errorWidget: (_, _, _) => Container(
                        height: 65,
                        color: AppColors.greyShade300,
                        child: const Icon(Icons.school_outlined, color: AppColors.grey),
                      ),
                    )
                  : Container(
                      height: 65,
                      color: AppColors.greyShade300,
                      child: const Icon(Icons.school_outlined, color: AppColors.grey),
                    ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                course.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            if (course.excerpt.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  course.excerpt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.greyShade700),
                ),
              ),
            ],
            if (course.authorName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "By ${course.authorName}",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TapScale(
                onTap: () => _openCourse(course),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 35,
                  width: double.infinity,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0xFF6C9B6E)),
                  child: const Center(
                    child: Text("Start Learning", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
