import 'package:flutter/material.dart';

import 'edit_profile_page.dart';
import 'change_email_page.dart';
import 'change_password_page.dart';

class SettingsPage extends StatelessWidget {

  const SettingsPage({super.key});

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

                    "Settings",

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
              // Account Section
              // ======================

              const Text(

                "Account",

                style: TextStyle(

                  fontSize: 18,

                  fontWeight:
                      FontWeight.bold,

                ),

              ),

              const SizedBox(height: 15),

              _buildTile(

                context,

                icon: Icons.person_outline,

                title: "Edit Profile",

                onTap: () {

                  Navigator.push(

                    context,

                    MaterialPageRoute(

                      builder: (context) =>
                          const EditProfilePage(),

                    ),

                  );

                },

              ),

              _buildTile(

                context,

                icon: Icons.email_outlined,

                title: "Change Email",

                onTap: () {

                  Navigator.push(

                    context,

                    MaterialPageRoute(

                      builder: (context) =>
                          const ChangeEmailPage(),

                    ),

                  );

                },

              ),

              _buildTile(

                context,

                icon: Icons.lock_outline,

                title: "Change Password",

                onTap: () {

                  Navigator.push(

                    context,

                    MaterialPageRoute(

                      builder: (context) =>
                          const ChangePasswordPage(),

                    ),

                  );

                },

              ),
              const SizedBox(height: 30),

// ======================
// Preferences Section
// ======================

const Text(

  "Preferences",

  style: TextStyle(

    fontSize: 18,

    fontWeight: FontWeight.bold,

  ),

),

const SizedBox(height: 15),

_buildTile(

  context,

  icon: Icons.notifications_outlined,

  title: "Notifications",

  onTap: () {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      const SnackBar(

        content: Text(
          "Notifications page coming soon",
        ),

      ),

    );

  },

),

_buildTile(

  context,

  icon: Icons.privacy_tip_outlined,

  title: "Privacy",

  onTap: () {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      const SnackBar(

        content: Text(
          "Privacy settings coming soon",
        ),

      ),

    );

  },

),

_buildTile(

  context,

  icon: Icons.help_outline,

  title: "Help Center",

  onTap: () {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      const SnackBar(

        content: Text(
          "Help Center coming soon",
        ),

      ),

    );

  },

),

_buildTile(

  context,

  icon: Icons.info_outline,

  title: "About App",

  onTap: () {

    showAboutDialog(

      context: context,

      applicationName: "K54",

      applicationVersion: "1.0.0",

      applicationLegalese:
          "© 2026 K54 Community Platform",

    );

  },

),

const SizedBox(height: 30),

// ======================
// Logout
// ======================

SizedBox(

  width: double.infinity,

  height: 55,

  child: ElevatedButton.icon(

    onPressed: () {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Logged out successfully",
          ),

        ),

      );

    },

    style: ElevatedButton.styleFrom(

      backgroundColor: Colors.red,

      shape: RoundedRectangleBorder(

        borderRadius:
            BorderRadius.circular(15),

      ),

    ),

    icon: const Icon(
      Icons.logout,
      color: Colors.white,
    ),

    label: const Text(

      "Logout",

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

        ),

      ),

    );

  }

  Widget _buildTile(

    BuildContext context, {

    required IconData icon,

    required String title,

    required VoidCallback onTap,

  }) {

    return Card(

      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      elevation: 0,

      color: const Color(0xFFF5EFD9),

      shape: RoundedRectangleBorder(

        borderRadius:
            BorderRadius.circular(15),

      ),

      child: ListTile(

        leading: Icon(

          icon,

          color: const Color(0xFF008000),

        ),

        title: Text(title),

        trailing: const Icon(
          Icons.chevron_right,
        ),

        onTap: onTap,

      ),

    );

  }

}