import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';

import 'package:k54_mobile/features/activity/models/reaction_type.dart';

/// Renders one reaction's glyph - the plain "Like" entry has no remote
/// icon_path (rendered as a colored thumbs-up), the other five are real
/// twemoji SVG URLs from BuddyBoss's own confirmed `/buddyboss/v1/reactions`
/// response, not locally-bundled emoji.
class ReactionGlyph extends StatelessWidget {
  final ReactionType type;
  final double size;

  const ReactionGlyph({super.key, required this.type, this.size = 20});

  @override
  Widget build(BuildContext context) {
    if (type.isPlainLike) {
      // BuddyBoss's own default `icon_color` for the plain Like reaction is
      // a Facebook-style blue - confirmed real (reported live: the like
      // button turned blue once real reaction types loaded, overriding the
      // green fallback used before that). Brand green always wins here
      // instead of trusting the backend's own color for this one glyph.
      return Icon(Icons.thumb_up, size: size, color: AppColors.green);
    }
    return Image.network(
      type.iconPath,
      width: size,
      height: size,
      errorBuilder: (_, _, _) => Text(
        type.iconText.isNotEmpty ? type.iconText[0] : "?",
        style: TextStyle(fontSize: size * 0.7),
      ),
    );
  }
}

/// Long-press reaction bar (Like/Love/Laugh/Angry/Sad/Wow) anchored above
/// the like button via [layerLink] - the real Facebook-style pattern the
/// button's plain tap-to-toggle can't express on its own. Self-removes on
/// selection or on a tap outside the popup.
void showReactionPicker({
  required BuildContext context,
  required LayerLink layerLink,
  required List<ReactionType> reactions,
  required ValueChanged<ReactionType> onSelected,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        // Full-screen tap-away barrier, below the popup itself.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => entry.remove(),
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          offset: const Offset(-8, -12),
          child: Material(
            color: AppColors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: reactions.map((r) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _ReactionOption(
                      type: r,
                      onTap: () {
                        entry.remove();
                        onSelected(r);
                      },
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

/// A single reaction option in the picker - grows slightly on press so
/// picking a reaction has the same tactile "alive" feedback as the rest of
/// the app, not a flat tap target.
class _ReactionOption extends StatefulWidget {
  final ReactionType type;
  final VoidCallback onTap;

  const _ReactionOption({required this.type, required this.onTap});

  @override
  State<_ReactionOption> createState() => _ReactionOptionState();
}

class _ReactionOptionState extends State<_ReactionOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 1.3 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ReactionGlyph(type: widget.type, size: 30),
      ),
    );
  }
}
