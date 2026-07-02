import 'package:flutter/material.dart';

class ProfileMenu extends StatelessWidget {
  final Function(String) onSelected;

  const ProfileMenu({
    super.key,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz),

      onSelected: onSelected,

      itemBuilder: (context) => const [

        PopupMenuItem(
          value: "edit",
          child: Row(
            children: [
              Icon(Icons.edit),
              SizedBox(width: 10),
              Text("Edit Profile"),
            ],
          ),
        ),

        PopupMenuItem(
          value: "email",
          child: Row(
            children: [
              Icon(Icons.email_outlined),
              SizedBox(width: 10),
              Text("Change Email"),
            ],
          ),
        ),

        PopupMenuItem(
          value: "password",
          child: Row(
            children: [
              Icon(Icons.lock_outline),
              SizedBox(width: 10),
              Text("Change Password"),
            ],
          ),
        ),

        PopupMenuItem(
          value: "settings",
          child: Row(
            children: [
              Icon(Icons.settings_outlined),
              SizedBox(width: 10),
              Text("Settings"),
            ],
          ),
        ),

        PopupMenuDivider(),

        PopupMenuItem(
          value: "logout",
          child: Row(
            children: [
              Icon(Icons.logout),
              SizedBox(width: 10),
              Text("Logout"),
            ],
          ),
        ),

      ],
    );
  }
}