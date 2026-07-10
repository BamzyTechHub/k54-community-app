import 'package:flutter/material.dart';

/// The real, confirmed button color scheme from k54global.com's own CSS
/// (pulled directly from the live page's custom-property values, not
/// Figma - Figma's static renders show a bold green/gold/green gradient
/// for the same buttons, which is what every button in this app matched
/// until now; per direct instruction (2026-07-10) the live site wins for
/// button color specifically):
///   --bb-primary-button-background-regular: #B9D6AD (text #000000)
///   --bb-primary-button-background-hover:   #AB8000 (text #FFFFFF)
/// Flutter mobile has no mouse hover, so "hover" maps to the pressed
/// state - held via GestureDetector's onTapDown/onTapUp/onTapCancel
/// rather than a static color, so it actually animates like a real
/// hover/press would, not just flip instantly.
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 55,
    this.icon,
  });

  static const _regularBg = Color(0xFFB9D6AD);
  static const _pressedBg = Color(0xFFAB8000);
  static const _regularText = Colors.black;
  static const _pressedText = Colors.white;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null || widget.loading) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;
    final bg = disabled
        ? PrimaryButton._regularBg.withValues(alpha: 0.5)
        : (_pressed ? PrimaryButton._pressedBg : PrimaryButton._regularBg);
    final fg = _pressed ? PrimaryButton._pressedText : PrimaryButton._regularText;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.loading ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.height / 2),
        ),
        child: Center(
          child: widget.loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
