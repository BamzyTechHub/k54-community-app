import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/features/profile/widgets/profile_tabs.dart';

/// The profile's "..." menu - always offers the same fixed 6 destinations
/// (ProfileTabs.menuTabs), regardless of which tab is currently active;
/// confirmed by the Figma screenshots showing an identical list every
/// time the menu is opened, even after the visible 3-tab window has
/// slid to show different tabs. [onSelected] receives the tab's label
/// directly (e.g. "Groups", "Account Settings") - ProfilePage handles
/// what that means (slide it into the tab window vs. push a real page
/// for Account Settings).
///
/// Not a plain PopupMenuButton - Figma shows the whole page behind the
/// menu dimmed while it's open (an "inactive" background state), which
/// Flutter's default popup menu doesn't do on its own. Same OverlayEntry
/// pattern as the reaction/filter popovers elsewhere in this app, but
/// with a real dark scrim instead of a transparent tap-away barrier.
class ProfileMenu extends StatefulWidget {
  final String? selectedLabel;
  final ValueChanged<String> onSelected;

  const ProfileMenu({super.key, this.selectedLabel, required this.onSelected});

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  final LayerLink _layerLink = LayerLink();

  void _open() {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // The dimmed "inactive" background state, not a plain
          // transparent tap-away barrier - matches Figma showing the
          // whole page behind the menu darkened while it's open.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => entry.remove(),
              child: Container(color: AppColors.black.withValues(alpha: 0.35)),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 8),
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 6,
              shadowColor: AppColors.black.withValues(alpha: 0.3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: ProfileTabs.menuTabs.map((label) {
                    final selected = label == widget.selectedLabel;
                    return TapScale(
                      onTap: () {
                        entry.remove();
                        widget.onSelected(label);
                      },
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: selected ? const Color(0xFFE8EFE8) : AppColors.transparent,
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: selected ? AppColors.green : AppColors.jetBlack,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TapScale(
        onTap: _open,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.more_horiz),
        ),
      ),
    );
  }
}
