import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';

/// The cream pill search field - previously duplicated with two
/// conflicting visual families (this look vs. a separate grey Material
/// `filled` field) across 8 screens. This one wins because it's the
/// version directly confirmed against real Figma exports (Home, Members,
/// Groups, Help Center, Search).
///
/// Fill color corrected 2026-07-18: was AppColors.groupCardBackground
/// (#E3DAC1, a tan/gold tone), which read as visibly gold-tinted on
/// Members/Messages/Friends/Groups - flagged directly by the user. The
/// Homepage's own search pill was independently re-measured against the
/// live Figma JSON on 2026-07-16 and uses #FCF8ED (a much lighter cream)
/// with #1A1A1A icon/text - this shared widget had drifted out of sync
/// with that confirmed value ever since. Now both match.
class K54SearchField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;
  final double height;
  final double iconSize;
  final double fontSize;

  const K54SearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = "Search",
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.height = 40,
    this.iconSize = 16,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF8ED),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: iconSize, color: AppColors.jetBlack),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: autofocus,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: GoogleFonts.poppins(fontSize: fontSize, color: AppColors.jetBlack.withValues(alpha: 0.5)),
              ),
              style: GoogleFonts.poppins(fontSize: fontSize, color: AppColors.jetBlack),
            ),
          ),
        ],
      ),
    );
  }
}
