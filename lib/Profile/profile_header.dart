import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userTitle;
  final String userImage;

  const ProfileHeader({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userTitle,
    required this.userImage,
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider imageProvider =
        userImage.startsWith("http")
            ? NetworkImage(userImage)
            : AssetImage(userImage);

    return Column(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),

        Transform.translate(
          offset: const Offset(0, -45),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: imageProvider,
            ),
          ),
        ),

        Text(
          userName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          userTitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          userEmail,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}