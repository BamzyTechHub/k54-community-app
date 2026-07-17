import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';

/// The underline-selected tab row used by Profile, Members, and Groups -
/// previously 3 separately hand-written copies with drifting font size
/// (13 on Profile, 10 on the other two). One widget now, standardized on
/// 13 since that was the original/fullest-spec copy.
class UnderlineTabRow extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double fontSize;

  const UnderlineTabRow({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    // Always horizontally scrollable - never clips, and costs nothing
    // when the tabs already fit (a SingleChildScrollView with content
    // narrower than the viewport just doesn't scroll). A fixed-width Row
    // here previously clipped Members'/Groups' tabs on narrower phones -
    // a real regression, not a Figma question.
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(tabs.length, (index) {
        final isSelected = selectedIndex == index;
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TapScale(
            onTap: () => onChanged(index),
            child: Container(
              padding: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppColors.green : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabs[index],
                // Was always jetBlack regardless of selection - only the
                // underline changed color. A real device screenshot
                // (2026-07-18) shows the active tab's text itself in
                // green/bold too, inactive tabs in a muted grey.
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  color: isSelected ? AppColors.green : Colors.grey.shade500,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }),
    );

    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: row);
  }
}
