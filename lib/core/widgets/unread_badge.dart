import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
              Positioned(
                right: -4,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    value > 9 ? "9+" : "$value",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
