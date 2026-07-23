import 'package:flutter/material.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';

/// The "Create a Group" form, used by GroupsPage's own "Create a Group"
/// tab. The AI Assistant's "Create NGO Community"/"Create Church Group"/
/// "Start Study Group" quick actions used to share this same dialog, but
/// now use a real scripted in-chat Q&A instead (see AiChatController) -
/// not this popup. Returns the entered details, or null if cancelled -
/// callers own what happens next (which repository/endpoint actually
/// creates the group).
Future<({String name, String description, String privacy})?> showCreateGroupDialog(
  BuildContext context, {
  String initialName = "",
}) async {
  final nameController = TextEditingController(text: initialName);
  final descController = TextEditingController();
  String privacy = "public";

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => K54Dialog(
        title: "Create a Group",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Group Name")),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: privacy,
              decoration: const InputDecoration(labelText: "Privacy"),
              items: const [
                DropdownMenuItem(value: "public", child: Text("Public")),
                DropdownMenuItem(value: "private", child: Text("Private")),
                DropdownMenuItem(value: "hidden", child: Text("Hidden")),
              ],
              onChanged: (value) => setDialogState(() => privacy = value ?? "public"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.greyShade600)),
          ),
          // Explicit brand green, not Flutter's default Material
          // primary - flagged directly by a tester ("current colors
          // aren't brand colors").
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Create", style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true || nameController.text.trim().isEmpty) return null;
  return (name: nameController.text.trim(), description: descController.text.trim(), privacy: privacy);
}
