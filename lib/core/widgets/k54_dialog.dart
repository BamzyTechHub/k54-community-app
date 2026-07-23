import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';

/// Consistent rounded-corner shape for every dialog in the app -
/// previously only Help Center's contact-sheet dialog had a custom
/// radius (16px); every other `AlertDialog` used Flutter's sharp-cornered
/// Material default. Applying the same rounded shape everywhere reads as
/// a deliberate design choice instead of one dialog looking hand-tuned
/// and the rest looking untouched.
class K54Dialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const K54Dialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  static const shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: shape,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: content,
      actions: actions,
    );
  }
}

/// Opens a bottom sheet with the app's standard rounded-top shape and
/// white background - previously only Comments used this styling;
/// Messages' thread-actions sheet used Flutter's plain square-cornered
/// default, so the two looked like they belonged to different apps.
Future<T?> showK54BottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: builder,
  );
}
