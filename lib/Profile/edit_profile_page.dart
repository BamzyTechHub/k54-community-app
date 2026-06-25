import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() =>
      _EditProfilePageState();
}

class _EditProfilePageState
    extends State<EditProfilePage> {

  final TextEditingController nameController =
    TextEditingController(
  text: UserProfile.name,
);

final TextEditingController usernameController =
    TextEditingController(
  text: UserProfile.username,
);

final TextEditingController bioController =
    TextEditingController(
  text: UserProfile.bio,
);

final TextEditingController phoneController =
    TextEditingController(
  text: UserProfile.phone,
);

final TextEditingController locationController =
    TextEditingController(
  text: UserProfile.location,
);

final TextEditingController websiteController =
    TextEditingController(
  text: UserProfile.website,
);
  @override
  void dispose() {

    nameController.dispose();
    usernameController.dispose();
    bioController.dispose();
    phoneController.dispose();
    locationController.dispose();
    websiteController.dispose();
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

      body: SafeArea(

        child: SingleChildScrollView(

          child: Padding(

            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),

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

                      "Edit Profile",

                      style: TextStyle(

                        fontSize: 24,

                        fontWeight:
                            FontWeight.bold,

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 30),

                // ======================
                // Profile Image
                // ======================

                Center(

                  child: Column(

                    children: [

                      const CircleAvatar(

                        radius: 55,

                        backgroundImage:
                            AssetImage(
                          "assets/images/member1.png",
                        ),

                      ),

                      const SizedBox(height: 10),

                      TextButton(

                        onPressed: () {

                          // Change photo later

                        },

                        child: const Text(
                          "Change Photo",
                        ),

                      ),

                    ],

                  ),

                ),

                const SizedBox(height: 25),

                // ======================
                // Full Name
                // ======================

                const Text(

                  "Full Name",

                  style: TextStyle(

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

                const SizedBox(height: 8),

                TextField(

                  controller: nameController,

                  decoration: InputDecoration(

                    filled: true,

                    fillColor:
                        const Color(0xFFF5EFD9),

                    border:
                        OutlineInputBorder(

                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),

                    ),

                  ),

                ),

                const SizedBox(height: 20),

                // ======================
                // Username
                // ======================

                const Text(

                  "Username",

                  style: TextStyle(

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

                const SizedBox(height: 8),

                TextField(

                  controller:
                      usernameController,

                  decoration: InputDecoration(

                    filled: true,

                    fillColor:
                        const Color(0xFFF5EFD9),

                    border:
                        OutlineInputBorder(

                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),

                    ),

                  ),

                ),

                const SizedBox(height: 20),

// ======================
// Bio
// ======================

const Text(

  "Bio",

  style: TextStyle(

    fontWeight: FontWeight.bold,

  ),

),

const SizedBox(height: 8),

TextField(

  maxLines: 3,

  controller: bioController,

  decoration: InputDecoration(

    hintText:
        "Tell people about yourself...",

    filled: true,

    fillColor:
        const Color(0xFFF5EFD9),

    border: OutlineInputBorder(

      borderRadius:
          BorderRadius.circular(15),

    ),

  ),

),

const SizedBox(height: 20),

// ======================
// Phone Number
// ======================

const Text(

  "Phone Number",

  style: TextStyle(

    fontWeight: FontWeight.bold,

  ),

),

const SizedBox(height: 8),

TextField(
  controller: phoneController,
  keyboardType: TextInputType.phone,

  decoration: InputDecoration(

    hintText: "+234",

    filled: true,

    fillColor:
        const Color(0xFFF5EFD9),

    border: OutlineInputBorder(

      borderRadius:
          BorderRadius.circular(15),

    ),

  ),

),

const SizedBox(height: 20),

// ======================
// Location
// ======================

const Text(

  "Location",

  style: TextStyle(

    fontWeight: FontWeight.bold,

  ),

),

const SizedBox(height: 8),

TextField(

  controller: locationController,
  decoration: InputDecoration(

    hintText: "Lagos, Nigeria",

    filled: true,

    fillColor:
        const Color(0xFFF5EFD9),

    border: OutlineInputBorder(

      borderRadius:
          BorderRadius.circular(15),

    ),

  ),

),

const SizedBox(height: 20),

// ======================
// Website
// ======================

const Text(

  "Website",

  style: TextStyle(

    fontWeight: FontWeight.bold,

  ),

),

const SizedBox(height: 8),

TextField(

  controller: websiteController,
  decoration: InputDecoration(

    hintText:
        "https://yourwebsite.com",

    filled: true,

    fillColor:
        const Color(0xFFF5EFD9),

    border: OutlineInputBorder(

      borderRadius:
          BorderRadius.circular(15),

    ),

  ),

),

const SizedBox(height: 30),
      // ======================
// Action Buttons
// ======================

Row(

  children: [

    // Discard Button

    Expanded(

      child: OutlinedButton(

        onPressed: () {

          Navigator.pop(context);

        },

        style: OutlinedButton.styleFrom(

          minimumSize: const Size(
            double.infinity,
            55,
          ),

          side: const BorderSide(
            color: Color(0xFF008000),
          ),

          shape: RoundedRectangleBorder(

            borderRadius:
                BorderRadius.circular(15),

          ),

        ),

        child: const Text(

          "Discard",

          style: TextStyle(

            color: Color(0xFF008000),

            fontWeight:
                FontWeight.bold,

          ),

        ),

      ),

    ),

    const SizedBox(width: 15),

    // Save Button

    Expanded(

      child: ElevatedButton(

       onPressed: () {

  UserProfile.name =
      nameController.text;

  UserProfile.username =
      usernameController.text;

  UserProfile.bio =
      bioController.text;

  UserProfile.phone =
      phoneController.text;

  UserProfile.location =
      locationController.text;

  UserProfile.website =
      websiteController.text;

  ScaffoldMessenger.of(context)
      .showSnackBar(
    const SnackBar(
      content: Text(
        "Profile updated successfully",
      ),
    ),
  );

  Navigator.pop(context);
},

        style: ElevatedButton.styleFrom(

          backgroundColor:
              const Color(0xFF008000),

          minimumSize: const Size(
            double.infinity,
            55,
          ),

          shape: RoundedRectangleBorder(

            borderRadius:
                BorderRadius.circular(15),

          ),

        ),

        child: const Text(

          "Save Changes",

          style: TextStyle(

            color: Colors.white,

            fontWeight:
                FontWeight.bold,

          ),

        ),

      ),

    ),

  ],

),

const SizedBox(height: 30),

              ],

            ),

          ),

        ),

      ),

    );

  }

}