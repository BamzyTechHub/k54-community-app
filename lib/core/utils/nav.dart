import 'package:flutter/material.dart';
import 'package:k54_mobile/features/home/screens/home_page.dart';

/// The 5 bottom-nav tab screens (Home/AI/Members/Groups/Courses) navigate
/// between each other via pushReplacement, so a plain Navigator.pop() on
/// any of them has nothing to pop to - their back arrows should return to
/// Home the same way the bottom nav itself would.
void goHome(BuildContext context) {
  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
}
