import 'package:flutter/material.dart';

import 'package:k54_mobile/core/services/api_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/features/auth/screens/splash1.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved JWT into Dio
  await ApiService.instance.initialize();

  runApp(const MyApp());
}

/// Flutter's default Android scroll physics (ClampingScrollPhysics) has
/// no overscroll bounce and feels noticeably stiffer than LinkedIn/
/// Facebook's lists - applying BouncingScrollPhysics everywhere via a
/// single ScrollBehavior override gets that "fluid" feel app-wide
/// without touching every individual ListView/GridView.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: _AppScrollBehavior(),
      // A single shared SnackBar look (floating, rounded, dark) instead
      // of Flutter's plain full-width default banner - applies to all
      // ~70 `ScaffoldMessenger.showSnackBar` call sites app-wide without
      // touching any of them individually.
      theme: ThemeData(
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.jetBlack,
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: const Splash1(),
    );
  }
}
