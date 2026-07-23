import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';

/// Wraps any icon with a small red unread-count badge that updates
/// automatically whenever [count] changes - no manual refresh calls
/// needed at the call site. Generic (moved out of the messaging feature)
/// so it can badge any unread-count source - messages, notifications, etc.
class UnreadBadge extends StatelessWidget {
  final Widget child;
  final ValueListenable<int> count;

  const UnreadBadge({super.key, required this.child, required this.count});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: count,
      builder: (context, value, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (value > 0)
              // Was minWidth/minHeight 16 with 5px horizontal padding - on
              // a "9+" count that stretched wide enough to nearly cover a
              // 24px bell icon entirely (flagged directly: "reduce the
              // size... it's currently covering the whole bell").
              Positioned(
                right: -3,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                  constraints: const BoxConstraints(minWidth: 13, minHeight: 13),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.white, width: 1.2),
                  ),
                  child: Text(
                    value > 9 ? "9+" : "$value",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
