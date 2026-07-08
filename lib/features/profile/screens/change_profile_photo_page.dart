import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';

/// Matches the K54 Figma file's Change Profile Photo screen exactly
/// (node 310:2239, rendered 2026-07-08).
///
/// All four actions are stubbed: the avatar-upload endpoint
/// (`/buddyboss/v1/members/{id}/avatar`) is confirmed to exist, but its
/// multipart request shape has never been captured - the same blocker
/// already documented for Activity Feed's featured-image upload. Sending
/// a guessed multipart body risks a silent wrong upload, not just a
/// visible error, so this shows "coming soon" rather than attempting one.
class ChangeProfilePhotoPage extends StatefulWidget {
  const ChangeProfilePhotoPage({super.key});

  @override
  State<ChangeProfilePhotoPage> createState() => _ChangeProfilePhotoPageState();
}

class _ChangeProfilePhotoPageState extends State<ChangeProfilePhotoPage> {
  String _avatarUrl = "";
  bool _loading = true;

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
                child: _loading
                    ? const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : CircleAvatar(
                        radius: 100,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                        child: _avatarUrl.isEmpty ? const Icon(Icons.person, size: 80) : null,
                      ),
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
                onTap: () => _comingSoon("Selecting from gallery"),
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
                onTap: () => _comingSoon("Removing your photo"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
