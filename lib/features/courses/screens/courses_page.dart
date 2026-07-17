import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/responsive.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/core/widgets/filter_popover.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';


class CoursesPage extends StatefulWidget {

  const CoursesPage({super.key});


  @override
  State<CoursesPage> createState() => _CoursesPageState();

}


class _CoursesPageState extends State<CoursesPage> {

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature isn't available yet")),
    );
  }

  // Filter Option
  String selectedFilter = "Release Date (newest first)";
  final LayerLink _filterLayerLink = LayerLink();

  // Real client-side sort of the course list below - previously the
  // dropdown updated `selectedFilter` but never actually reordered
  // `courses`, so picking any option looked like it did nothing. This
  // whole screen is still dummy/placeholder data (Tutor LMS's real course
  // endpoint exists but isn't wired yet - flagged separately, not part of
  // this fix), so "release date" has no real date field to sort by; newest/
  // oldest instead uses the authored order and its reverse, which is an
  // honest stand-in rather than inventing a fake date field.
  List<Map<String, String>> get _sortedCourses {
    final sorted = [...courses];
    switch (selectedFilter) {
      case "Release Date (oldest first)":
        return sorted.reversed.toList();
      case "Course Title (A-Z)":
        sorted.sort((a, b) => (a["title"] ?? "").compareTo(b["title"] ?? ""));
        return sorted;
      case "Course Title (Z-A)":
        sorted.sort((a, b) => (b["title"] ?? "").compareTo(a["title"] ?? ""));
        return sorted;
      default: // "Release Date (newest first)"
        return sorted;
    }
  }

  void _openFilterPopover() {
    const filters = [
      "Release Date (newest first)",
      "Release Date (oldest first)",
      "Course Title (A-Z)",
      "Course Title (Z-A)",
    ];
    showFilterPopover(
      context: context,
      layerLink: _filterLayerLink,
      sections: [
        FilterSection(
          label: "Course Filter",
          options: filters
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


  // Dummy Course Data
  final List<Map<String, String>> courses = [

    {
      "image": "assets/images/course1.png",
      "title": "K54 Global Growth Program",
      "lessons": "8",
      "duration": "1h 30m",
      "instructor": "Evelyn",
    },

    {
      "image": "assets/images/course2.png",
      "title": "K54 Digital Leadership",
      "lessons": "12",
      "duration": "2h 15m",
      "instructor": "Daniel",
    },

    {
      "image": "assets/images/course3.png",
      "title": "Community Building Masterclass",
      "lessons": "10",
      "duration": "1h 45m",
      "instructor": "Michael",
    },

    {
      "image": "assets/images/course4.png",
      "title": "Business Growth Strategy",
      "lessons": "15",
      "duration": "3h 00m",
      "instructor": "Sarah",
    },

    {
      "image": "assets/images/course5.png",
      "title": "Leadership Essentials",
      "lessons": "6",
      "duration": "55m",
      "instructor": "Grace",
    },

    {
      "image": "assets/images/course6.png",
      "title": "Startup Success Guide",
      "lessons": "9",
      "duration": "1h 20m",
      "instructor": "David",
    },

  ];


  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor: Colors.white,


      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.all(15),

          child: Column(

            children: [
              // Header Row

Row(

  children: [

    // No back arrow - Courses is a main bottom-nav destination (reached
    // via pushReplacement, same as AI Assistant/Members/Groups/Home),
    // not a pushed screen.
    const Text(

      "Courses",

      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),

    ),

    const Spacer(),


    // Filter trigger - opens the real floating "Course Filter" popover
    // (matches the Figma screenshot's custom card) instead of Flutter's
    // own default DropdownButton menu styling.
    CompositedTransformTarget(
      link: _filterLayerLink,
      child: TapScale(
        onTap: _openFilterPopover,
        borderRadius: BorderRadius.circular(7),
        child: Container(

          height: 28,

          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ),

          decoration: BoxDecoration(

            border: Border.all(
              color: AppColors.groupCardAccent,
            ),

            borderRadius: BorderRadius.circular(7),

          ),

          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedFilter,
                style: const TextStyle(fontSize: 11),
              ),
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


// Course Grid

Expanded(

  child: GridView.builder(

    itemCount: _sortedCourses.length,

    gridDelegate:
        SliverGridDelegateWithFixedCrossAxisCount(

      crossAxisCount: Responsive.gridColumns(context),

      crossAxisSpacing: 15,

      mainAxisSpacing: 15,

      childAspectRatio: 0.62,

    ),


    itemBuilder: (context, index) {


      final course = _sortedCourses[index];


      return FadeSlideIn(
        key: ValueKey(course["title"]),
        delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
        child: TapScale(
        onTap: () => _comingSoon(course["title"] ?? "This course"),
        borderRadius: BorderRadius.circular(20),
        child: Container(

        decoration: BoxDecoration(

          color: const Color(0xFFE8EFE8),

          // Radius 24 and image height 65 - exact match from node
          // 157:25's course card ("Frame 2147228245"), pulled via the
          // REST API 2026-07-16, was 20/90 before this measurement
          // existed.
          borderRadius: BorderRadius.circular(24),

        ),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // Course Image
ClipRRect(

  borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(24),
  ),

  child: Image.asset(

    course["image"]!,

    height: 65,

    width: double.infinity,

    fit: BoxFit.cover,

    errorBuilder: (_, _, _) => Container(
      height: 65,
      color: Colors.grey.shade300,
      child: const Icon(Icons.school_outlined, color: Colors.grey),
    ),

  ),

),


const SizedBox(height: 8),


// Rating Stars
const Padding(

  padding: EdgeInsets.symmetric(
    horizontal: 10,
  ),

  child: Row(

    children: [

      Icon(Icons.star_border,
          color: Color(0xFFAB8000),
          size: 16),

      Icon(Icons.star_border,
          color: Color(0xFFAB8000),
          size: 16),

      Icon(Icons.star_border,
          color: Color(0xFFAB8000),
          size: 16),

      Icon(Icons.star_border,
          color: Color(0xFFAB8000),
          size: 16),

      Icon(Icons.star_border,
          color: Color(0xFFAB8000),
          size: 16),

    ],

  ),

),


const SizedBox(height: 8),


// Course Title
Padding(

  padding: const EdgeInsets.symmetric(
    horizontal: 10,
  ),

  child: Text(

    course["title"]!,

    maxLines: 2,

    style: const TextStyle(

      fontWeight: FontWeight.bold,

      fontSize: 13,

    ),

  ),

),


const SizedBox(height: 8),


// Lessons & Duration
Padding(

  padding: const EdgeInsets.symmetric(
    horizontal: 10,
  ),

  child: Row(

    children: [

      const Icon(
        Icons.person_outline,
        size: 15,
      ),

      const SizedBox(width: 4),

      Text(
        course["lessons"]!,
        style: const TextStyle(fontSize: 12),
      ),


      const Spacer(),


      const Icon(
        Icons.access_time,
        size: 15,
      ),

      const SizedBox(width: 4),

      Text(
        course["duration"]!,
        style: const TextStyle(fontSize: 12),
      ),

    ],

  ),

),


const SizedBox(height: 8),


// Instructor
Padding(

  padding: const EdgeInsets.symmetric(
    horizontal: 10,
  ),

  child: Row(

    children: [

      const Icon(
        Icons.person,
        size: 15,
      ),

      const SizedBox(width: 6),

      Expanded(
        child: Text(

          "By ${course["instructor"]}",

          overflow: TextOverflow.ellipsis,

          style: const TextStyle(
            fontSize: 12,
          ),

        ),
      ),

    ],

  ),

),


const Spacer(),


// Start Learning Button
Padding(

  padding: const EdgeInsets.all(10),

  child: TapScale(
    onTap: () => _comingSoon(course["title"] ?? "This course"),
    borderRadius: BorderRadius.circular(20),
    child: Container(

    height: 35,

    width: double.infinity,

    decoration: BoxDecoration(

      borderRadius:
          BorderRadius.circular(20),

      color: const Color(0xFF6C9B6E),

    ),

    child: const Center(

      child: Text(

        "Start Learning",

        style: TextStyle(

          color: Colors.white,

          fontWeight: FontWeight.bold,

        ),

      ),

    ),

  ),
  ),

),

          ],

        ),

      ),
        ),
      );

    },

  ),

),

            ],

          ),

        ),

      ),


      // K54 Bottom Navigation
      bottomNavigationBar:
          const K54BottomNavigation(
        currentIndex: 4,
      ),

    );

  }

}