import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';

/// Empty states below match the live site's own profile tabs exactly
/// (fetched directly from k54global.com/members/{user}/documents|quizzes|
/// orders/ - no confirmed backend exists for any of these yet, so there's
/// real content to browse, just the honest empty state the website itself
/// shows). Figma has no design for these tabs at all.

/// Generic empty-state shared by Documents and Quizzes - same shape on
/// the live site, just different copy.
class ProfileEmptyTab extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? extra;

  const ProfileEmptyTab({super.key, required this.icon, required this.message, this.extra});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFD9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.groupMutedText),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.jetBlack),
          ),
          if (extra != null) ...[const SizedBox(height: 16), extra!],
        ],
      ),
    );
  }
}

/// Documents tab, matching the Figma "Upload Document" / "Create Folder"
/// design: Create Folder is real, wired to the confirmed live
/// `POST /buddyboss/v1/document/folder`. Upload Document stays an honest
/// "not available yet" tap - `/buddyboss/v1/document/upload` exists but
/// its OPTIONS schema declares no args (reads $_FILES directly), so the
/// multipart field name isn't discoverable from the API and isn't
/// guessed at. The list below is real (GET /buddyboss/v1/document).
class ProfileDocumentsTab extends StatefulWidget {
  const ProfileDocumentsTab({super.key});

  @override
  State<ProfileDocumentsTab> createState() => _ProfileDocumentsTabState();
}

class _ProfileDocumentsTabState extends State<ProfileDocumentsTab> {
  final BuddyBossService _service = BuddyBossService();
  List<Map<String, dynamic>>? _documents;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _documents = await _service.getDocuments();
    } catch (_) {
      _documents = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$feature isn't available yet")));
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: K54Dialog.shape,
        title: const Text("Create Folder"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Folder name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text("Create"),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    try {
      await _service.createDocumentFolder(title: name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Folder "$name" created')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't create folder: $e")));
    }
  }

  Widget _actionRow({required IconData icon, required String label, required VoidCallback onTap}) {
    return TapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF8ED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.green),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.jetBlack)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final documents = _documents ?? [];
    return Column(
      children: [
        _actionRow(
          icon: Icons.upload_file_outlined,
          label: "Upload Document",
          onTap: () => _comingSoon("Uploading documents"),
        ),
        _actionRow(icon: Icons.create_new_folder_outlined, label: "Create Folder", onTap: _createFolder),
        const SizedBox(height: 6),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(color: AppColors.green),
          )
        else if (documents.isEmpty)
          const ProfileEmptyTab(icon: Icons.description_outlined, message: "Sorry, no documents were found.")
        else
          ...documents.map((doc) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EFD9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      doc["type"] == "folder" ? Icons.folder_outlined : Icons.description_outlined,
                      color: AppColors.groupMutedText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (doc["title"] ?? doc["name"] ?? "Untitled").toString(),
                        style: GoogleFonts.lato(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}

/// Orders tab: matches the live site's WooCommerce-flavored empty state
/// exactly ("No orders!" + order-key recovery), not a generic message.
class ProfileOrdersTab extends StatelessWidget {
  const ProfileOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileEmptyTab(
      icon: Icons.receipt_long_outlined,
      message: "No orders!",
      extra: Column(
        children: [
          Text(
            "If you have a valid order key, you can recover it here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Order recovery isn't available yet")),
            ),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.green)),
            child: const Text("Recover"),
          ),
        ],
      ),
    );
  }
}

/// Courses tab: "Enrolled Courses" / "Created Courses" sub-tabs, matching
/// the live site exactly.
class ProfileCoursesTab extends StatefulWidget {
  const ProfileCoursesTab({super.key});

  @override
  State<ProfileCoursesTab> createState() => _ProfileCoursesTabState();
}

class _ProfileCoursesTabState extends State<ProfileCoursesTab> {
  int _subTab = 0;

  @override
  Widget build(BuildContext context) {
    const subTabs = ["Enrolled Courses", "Created Courses"];
    return Column(
      children: [
        Row(
          children: List.generate(subTabs.length, (index) {
            final selected = _subTab == index;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => setState(() => _subTab = index),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: selected ? AppColors.green : Colors.transparent, width: 2),
                    ),
                  ),
                  child: Text(
                    subTabs[index],
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.jetBlack),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        ProfileEmptyTab(
          icon: Icons.school_outlined,
          message: _subTab == 0
              ? "This member has not enrolled in any courses yet!"
              : "This member has not created any courses yet!",
        ),
      ],
    );
  }
}
