import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';
import 'package:k54_mobile/features/friends/repositories/friends_repository.dart';

/// Matches the K54 Figma file's Change Profile Photo screen exactly
/// (node 310:2239, rendered 2026-07-08).
///
/// Gallery upload and Remove Photo call the real
/// `/buddyboss/v1/members/{id}/avatar` REST endpoint (confirmed
/// registered via the site's public route index, 2026-07-14 - see
/// FriendsApiService's doc comment on the exact-shape caveat). Camera
/// capture and "Create Avatar" stay "coming soon": camera access needs
/// its own platform permission flow and "Create Avatar" has no backend
/// at all, neither is this endpoint's concern.
class ChangeProfilePhotoPage extends StatefulWidget {
  const ChangeProfilePhotoPage({super.key});

  @override
  State<ChangeProfilePhotoPage> createState() => _ChangeProfilePhotoPageState();
}

class _ChangeProfilePhotoPageState extends State<ChangeProfilePhotoPage> {
  String _avatarUrl = "";
  String _name = "";
  bool _loading = true;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      final response = await AuthService().getCurrentUser();
      _avatarUrl = response.data["avatar_urls"]?["full"] ??
          response.data["avatar_urls"]?["thumb"] ??
          "";
      _name = response.data["name"] ?? "";
    } catch (_) {
      // Non-fatal - just show the placeholder icon instead.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature is coming soon")),
    );
  }

  Future<void> _pickAndUpload() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final file = File(picked.path);
      await FriendsRepository.instance.uploadAvatar(
        fileBytes: await file.readAsBytes(),
        filename: picked.name,
      );
      await _loadAvatar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile photo updated")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't upload photo: $e")),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: K54Dialog.shape,
        title: const Text("Remove photo"),
        content: const Text("Remove your profile photo?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _uploading = true);
    try {
      await FriendsRepository.instance.deleteAvatar();
      await _loadAvatar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile photo removed")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't remove photo: $e")),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _option({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label, style: GoogleFonts.lato(fontSize: 16, color: AppColors.jetBlack)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Change Profile Photo",
                    style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: (_loading || _uploading)
                    ? const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                      )
                    : UserAvatar(imageUrl: _avatarUrl, name: _name, radius: 100),
              ),
              const SizedBox(height: 30),
              _option(
                icon: Icons.camera_alt_outlined,
                color: AppColors.green,
                label: "Take a New Photo",
                onTap: () => _comingSoon("Taking a new photo"),
              ),
              _option(
                icon: Icons.image_outlined,
                color: AppColors.green,
                label: "Select from Gallery",
                onTap: _uploading ? () {} : _pickAndUpload,
              ),
              _option(
                icon: Icons.face_retouching_natural,
                color: AppColors.gold,
                label: "Create Avatar",
                onTap: () => _comingSoon("Creating an avatar"),
              ),
              _option(
                icon: Icons.delete_outline,
                color: Colors.red,
                label: "Remove Photo",
                onTap: _uploading ? () {} : _removePhoto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
