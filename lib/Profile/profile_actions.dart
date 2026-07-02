import 'package:flutter/material.dart';
import 'edit_profile_page.dart';

class ProfileActions extends StatelessWidget {
  final bool isCurrentUser;

  const ProfileActions({
    super.key,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    if (isCurrentUser) {
      return Row(
        children: [

          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfilePage(),
                  ),
                );
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFF008000),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Edit Profile",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        ],
      );
    }

    return Row(
      children: [

        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF008000),
                  Color(0xFFAB8000),
                  Color(0xFF008000),
                ],
              ),
            ),
            child: const Center(
              child: Text(
                "Follow",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF008000),
                  Color(0xFFAB8000),
                  Color(0xFF008000),
                ],
              ),
            ),
            child: const Center(
              child: Text(
                "Connect",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

      ],
    );
  }
}