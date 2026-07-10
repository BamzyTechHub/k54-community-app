import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/nav.dart';
import 'package:k54_mobile/core/utils/responsive.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';


class CoursesPage extends StatefulWidget {

  const CoursesPage({super.key});


  @override
  State<CoursesPage> createState() => _CoursesPageState();

}


class _CoursesPageState extends State<CoursesPage> {


  // Filter Option
  String selectedFilter = "Release Date (newest first)";


  // Filter List
  final List<String> filters = [

    "Release Date (newest first)",

    "Release Date (oldest first)",

    "Course Title (A-Z)",

    "Course Title (Z-A)",

  ];


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

    IconButton(
      onPressed: () => goHome(context),
      icon: const Icon(
        Icons.arrow_back,
        size: 28,
      ),
    ),

    const SizedBox(width: 12),

    const Text(

      "Courses",

      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),

    ),

    const Spacer(),


    // Filter Dropdown
    Container(

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

      child: DropdownButton<String>(

        value: selectedFilter,

        underline: const SizedBox(),

        isDense: true,

        icon: const Icon(
          Icons.keyboard_arrow_down,
          size: 15,
        ),

        items: filters.map((item) {

          return DropdownMenuItem(

            value: item,

            child: Text(
              item,
              style: const TextStyle(
                fontSize: 11,
              ),
            ),

          );

        }).toList(),


        onChanged: (value) {

          setState(() {

            selectedFilter = value!;

          });

        },

      ),

    ),

  ],

),


const SizedBox(height: 20),


// Course Grid

Expanded(

  child: GridView.builder(

    itemCount: courses.length,

    gridDelegate:
        SliverGridDelegateWithFixedCrossAxisCount(

      crossAxisCount: Responsive.gridColumns(context),

      crossAxisSpacing: 15,

      mainAxisSpacing: 15,

      childAspectRatio: 0.62,

    ),


    itemBuilder: (context, index) {


      final course = courses[index];


      return Container(

        decoration: BoxDecoration(

          color: const Color(0xFFF6F8F4),

          borderRadius: BorderRadius.circular(20),

        ),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // Course Image
ClipRRect(

  borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
  ),

  child: Image.asset(

    course["image"]!,

    height: 90,

    width: double.infinity,

    fit: BoxFit.cover,

    errorBuilder: (_, _, _) => Container(
      height: 90,
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

          ],

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