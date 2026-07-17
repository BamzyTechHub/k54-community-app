import 'package:flutter/material.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/shimmer.dart';

/// Pre-built skeleton shapes matching the app's two most common list
/// layouts (the "list row" used by Friends/Groups/Messages, and the
/// "card" used by Members/Groups) - shown while real data is loading
/// instead of a bare spinner, the biggest single UX gap flagged in the
/// 2026-07-15 audit (no screen had a content-shaped loading state).
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.friendRowBackground,
          border: Border.all(color: AppColors.friendRowBorder),
        ),
        child: Row(
          children: [
            const SkeletonBox(width: 50, height: 50, radius: 25),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 14, width: 140),
                  SizedBox(height: 8),
                  SkeletonBox(height: 11, width: 90),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.groupCardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.groupCardAccent),
        ),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          children: const [
            SkeletonBox(width: 80, height: 80, radius: 40),
            SizedBox(height: 12),
            SkeletonBox(height: 14, width: 90),
            SizedBox(height: 8),
            SkeletonBox(height: 11, width: 60),
          ],
        ),
      ),
    );
  }
}

/// A vertical list of [SkeletonRow]s with a bit of staggered spacing -
/// drop-in replacement for `Center(child: CircularProgressIndicator())`
/// on any list-row screen's initial load.
class SkeletonRowList extends StatelessWidget {
  final int count;
  const SkeletonRowList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (_, _) => const SkeletonRow(),
    );
  }
}

/// Matches PostCard's shape (avatar + name/subtitle line, caption lines,
/// large image block) - for Timeline's initial load.
class SkeletonPost extends StatelessWidget {
  const SkeletonPost({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                SkeletonBox(width: 44, height: 44, radius: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 13, width: 120),
                      SizedBox(height: 6),
                      SkeletonBox(height: 10, width: 80),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const SkeletonBox(height: 12),
            const SizedBox(height: 8),
            const SkeletonBox(height: 12, width: 220),
            const SizedBox(height: 14),
            const SkeletonBox(height: 180, radius: 12),
          ],
        ),
      ),
    );
  }
}

/// Grid of [SkeletonCard]s - drop-in for card-grid screens (Members,
/// Groups full directory) on initial load.
class SkeletonCardGrid extends StatelessWidget {
  final int crossAxisCount;
  final int count;
  const SkeletonCardGrid({super.key, this.crossAxisCount = 2, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (_, _) => const SkeletonCard(),
    );
  }
}
