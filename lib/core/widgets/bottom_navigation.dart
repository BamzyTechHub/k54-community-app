import 'package:flutter/material.dart';
import 'package:k54_mobile/features/home/screens/home_page.dart';
import 'package:k54_mobile/features/ai/screens/ai_page.dart';
import 'package:k54_mobile/features/members/screens/members_page.dart';
import 'package:k54_mobile/features/groups/screens/groups_page.dart';
import 'package:k54_mobile/features/courses/screens/courses_page.dart';


class K54BottomNavigation extends StatelessWidget {

  final int currentIndex;

  const K54BottomNavigation({
    super.key,
    required this.currentIndex,
  });


   void _navigate(BuildContext context, int index) {

  if (index == currentIndex) return;

  Widget page;

  switch (index) {
    case 0:
      page = const HomePage();
      break;

    case 1:
      page = const AiPage();
      break;

    case 2:
      page = const MembersPage();
      break;

    case 3:
      page = const GroupsPage();
      break;

    case 4:
      page = const CoursesPage();
      break;

    default:
      page = const HomePage();
  }

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => page,
    ),
  );
}


  @override
  Widget build(BuildContext context) {

    return BottomNavigationBar(

      currentIndex: currentIndex,

      type: BottomNavigationBarType.fixed,

      selectedItemColor: const Color(0xFF008000),

      unselectedItemColor: Colors.grey,


       onTap: (index) async {
  await Future.delayed(Duration.zero);

  if (context.mounted) {
    _navigate(context, index);
  }
},


      items: const [

         BottomNavigationBarItem(
  icon: Icon(Icons.home),
  label: "Home",
),

BottomNavigationBarItem(
  icon: Icon(Icons.smart_toy),
  label: "AI",
),

BottomNavigationBarItem(
  icon: Icon(Icons.people),
  label: "Members",
),

BottomNavigationBarItem(
  icon: Icon(Icons.groups),
  label: "Groups",
),

BottomNavigationBarItem(
  icon: Icon(Icons.menu_book),
  label: "Courses",
),

],

);

}

}