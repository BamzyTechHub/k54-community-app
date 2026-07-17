import 'package:flutter/material.dart';

/// A softer, faster fade+slide transition than Flutter's plain default
/// `MaterialPageRoute` slide - used for the app's highest-traffic
/// navigations (opening a profile, a chat, a post's comments) so moving
/// between screens feels considered rather than like the platform
/// default nobody touched.
Route<T> k54Route<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
