import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';

/// Compact pill button (icon optional) sharing the same real site colors
/// and press feedback as PrimaryButton, for places that need several
/// buttons side by side rather than one full-width button - Profile's
/// Follow/Message/Connect row, AI Assistant's quick-action chips, etc.
class PressablePill extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool loading;
  final double height;

  const PressablePill({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
    this.filled = true,
    this.loading = false,
    this.height = 44,
  });

  @override
  State<PressablePill> createState() => _PressablePillState();
}

class _PressablePillState extends State<PressablePill> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || widget.loading) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = _pressed && !widget.loading;
    final bg = active
        ? AppColors.buttonPressedBg
        : (widget.filled ? AppColors.buttonRegularBg : Colors.transparent);
    final fg = active
        ? AppColors.buttonPressedText
        : (widget.filled ? AppColors.buttonRegularText : AppColors.green);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.loading ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.height / 2),
          border: (widget.filled || active) ? null : Border.all(color: AppColors.green, width: 1.5),
        ),
        child: Center(
          child: widget.loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 16, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      widget.label,
                      style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 13, color: fg),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
