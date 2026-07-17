import 'package:flutter/material.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';

/// Shared empty-state view (icon + message, optional action) - replaces
/// what used to be a bare `Center(child: Text("No X found"))` on every
/// list screen, with no icon and no visual weight.
class K54EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const K54EmptyState({super.key, required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14.5),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Shared error-state view (icon + message + Retry) - replaces the
/// hand-rolled "Couldn't load X.\n$error" + TextButton pattern
/// previously copy-pasted with slightly different spacing/wording on
/// every screen.
class K54ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const K54ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14.5),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18, color: AppColors.green),
              label: const Text("Retry", style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
