import 'package:flutter/material.dart';

class ChangeProfilePhotoPage extends StatelessWidget {

  const ChangeProfilePhotoPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),

          child: SingleChildScrollView(

  child: Column(
  
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // ======================
              // Header
              // ======================

              Row(

                children: [

                  IconButton(

                    onPressed: () {

                      Navigator.pop(context);

                    },

                    icon: const Icon(
                      Icons.arrow_back,
                    ),

                  ),

                  const SizedBox(width: 10),

                  const Text(

                    "Change Profile Photo",

                    style: TextStyle(

                      fontSize: 22,

                      fontWeight:
                          FontWeight.bold,

                    ),

                  ),

                ],

              ),

              const SizedBox(height: 30),

              // ======================
              // Profile Photo
              // ======================

                Center(

  child: Stack(

    children: [

      GestureDetector(

        onTap: () {},

        child: const CircleAvatar(

          radius: 70,

          backgroundImage: AssetImage(
            "assets/images/member1.png",
          ),

        ),

      ),

      Positioned(

        bottom: 0,

        right: 0,

        child: Container(

          padding: const EdgeInsets.all(8),

          decoration: const BoxDecoration(

            color: Color(0xFF008000),

            shape: BoxShape.circle,

          ),

          child: const Icon(

            Icons.edit,

            color: Colors.white,

            size: 18,

          ),

        ),

      ),

    ],

  ),

),

              const SizedBox(height: 40),
              // ======================
// Photo Options
// ======================

_buildOption(

  icon: Icons.camera_alt_outlined,

  color: const Color(0xFF008000),

  title: "Take a New Photo",

  onTap: () {

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(
          "Camera integration coming soon",
        ),

      ),

    );

  },

),

const SizedBox(height: 20),

_buildOption(

  icon: Icons.photo_library_outlined,

  color: const Color(0xFF7CB342),

  title: "Select from Gallery",

  onTap: () {

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(
          "Gallery integration coming soon",
        ),

      ),

    );

  },

),

const SizedBox(height: 20),

_buildOption(

  icon: Icons.face_outlined,

  color: const Color(0xFF8BC34A),

  title: "Create Avatar",

  onTap: () {

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(
          "Avatar creator coming soon",
        ),

      ),

    );

  },

),

const SizedBox(height: 20),

_buildOption(

  icon: Icons.delete_outline,

  color: Colors.red,

  title: "Remove Photo",

  onTap: () {

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(
          "Profile photo removed",
        ),

      ),

    );

  },

),
const SizedBox(height: 30),

Center(

  child: Text(

    "K54 Community",

    style: TextStyle(

      color: Colors.grey.shade500,

      fontSize: 13,

    ),

  ),

),

],

            ),

          ),

        ),

      ),

    );

  }
Widget _buildOption({

  required IconData icon,

  required Color color,

  required String title,

  required VoidCallback onTap,

}) {

  return InkWell(

    onTap: onTap,

    borderRadius: BorderRadius.circular(12),

    child: Container(

      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),

      child: Row(

        children: [

          Icon(

            icon,

            color: color,

            size: 24,

          ),

          const SizedBox(width: 15),

          Text(

            title,

            style: const TextStyle(

              fontSize: 16,

              fontWeight: FontWeight.w500,

            ),

          ),

        ],

      ),

    ),

  );

}
}