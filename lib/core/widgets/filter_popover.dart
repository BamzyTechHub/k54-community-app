import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';

/// One selectable row inside a [FilterSection].
class FilterOption {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterOption({required this.label, required this.selected, required this.onTap});
}

/// One labeled card of options inside the popover (e.g. "Members view
/// filter", "Course Filter").
class FilterSection {
  final String label;
  final List<FilterOption> options;

  const FilterSection({required this.label, required this.options});
}

/// Shared floating filter popover - anchored below a header icon via
/// [layerLink], one rounded white card per [FilterSection], selected
/// options highlighted. Used by Members/Groups/Courses' filter icons
/// (previously three separately hand-written, near-identical popovers).
/// Same OverlayEntry + tap-away-barrier pattern as the post reaction
/// picker.
void showFilterPopover({
  required BuildContext context,
  required LayerLink layerLink,
  required List<FilterSection> sections,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  Widget sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.greyShade600, fontWeight: FontWeight.w600),
        ),
      );

  Widget optionRow(FilterOption option) {
    return TapScale(
      onTap: () {
        entry.remove();
        option.onTap();
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: option.selected ? const Color(0xFFE8EFE8) : AppColors.transparent,
        child: Text(
          option.label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: option.selected ? AppColors.green : AppColors.jetBlack,
            fontWeight: option.selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget card(FilterSection section) => Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 6,
        shadowColor: AppColors.black.withValues(alpha: 0.2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionLabel(section.label),
              ...section.options.map(optionRow),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );

  entry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => entry.remove(),
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < sections.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                card(sections[i]),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  overlay.insert(entry);
}
