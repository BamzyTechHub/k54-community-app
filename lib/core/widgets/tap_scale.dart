import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';

/// Wraps any widget with the "press down slightly, spring back" feedback
/// that makes LinkedIn/Facebook/Instagram-style cards feel alive - most
/// tappable cards and list rows in this app used a plain GestureDetector
/// with zero visual response to touch, which reads as static/unfinished
/// regardless of how correct the layout is. Combines a subtle scale-down
/// with a real Material ripple so it works well on both a card-shaped
/// surface and a plain row.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final Color? splashColor;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.splashColor,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Material(
          color: AppColors.transparent,
          borderRadius: widget.borderRadius,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            borderRadius: widget.borderRadius,
            splashColor: widget.splashColor,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
