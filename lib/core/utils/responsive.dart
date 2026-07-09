import 'package:flutter/widgets.dart';

/// Shared breakpoint helpers. The app was built screen-by-screen against
/// Figma's 390px mobile frames, so most grids/lists had their column
/// counts and sizes hardcoded for a phone; this is the single place that
/// decides how those choices scale up for tablets, rather than each
/// screen guessing its own breakpoint.
class Responsive {
  Responsive._();

  static const double tabletBreakpoint = 700;
  static const double largeTabletBreakpoint = 1000;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// Grid column count for card-style lists (members, courses, connections).
  /// Phones keep the Figma-matched 2 columns; tablets get more room per
  /// row instead of two oversized cards with empty space on either side.
  static int gridColumns(BuildContext context, {int phoneColumns = 2}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= largeTabletBreakpoint) return phoneColumns + 2;
    if (width >= tabletBreakpoint) return phoneColumns + 1;
    return phoneColumns;
  }
}
