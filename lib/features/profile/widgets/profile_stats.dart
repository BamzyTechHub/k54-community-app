import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';

class ProfileStats extends StatelessWidget {
  final int followers;
  final int following;
  final int posts;

  const ProfileStats({
    super.key,
    required this.followers,
    required this.following,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFD9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,
        children: [

          _buildStat(
            followers.toString(),
            "Followers",
          ),

          _buildStat(
            following.toString(),
            "Following",
          ),

          _buildStat(
            posts.toString(),
            "Posts",
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    String value,
    String label,
  ) {
    return Column(
      children: [
        // Brand green, not black - direct tester feedback that the
        // numbers themselves should be green too, not just the labels.
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.green,
          ),
        ),

        const SizedBox(height: 4),

        // Brand green, not grey - flagged directly in tester feedback.
        Text(
          label,
          style: const TextStyle(
            color: AppColors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
