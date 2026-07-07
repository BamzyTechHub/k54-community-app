import 'package:flutter/material.dart';

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
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}