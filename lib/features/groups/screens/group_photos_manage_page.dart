import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/pressable_pill.dart';
import 'package:k54_mobile/features/groups/models/group_model.dart';
import 'package:k54_mobile/features/groups/repositories/groups_repository.dart';

/// Group avatar/cover upload - confirmed real routes live 2026-07-22
/// (`POST buddyboss/v1/groups/{id}/avatar` and `.../cover`, same `file`
/// multipart shape as every other BuddyBoss attachment upload in this app).
class GroupPhotosManagePage extends StatefulWidget {
  final Group group;

  const GroupPhotosManagePage({super.key, required this.group});

  @override
  State<GroupPhotosManagePage> createState() => _GroupPhotosManagePageState();
}

class _GroupPhotosManagePageState extends State<GroupPhotosManagePage> {
  final ImagePicker _picker = ImagePicker();
  bool _uploadingAvatar = false;
  bool _uploadingCover = false;
  String? _avatarUrl;
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.group.avatarUrl;
    _coverUrl = widget.group.coverUrl;
  }

  Future<void> _pickAndUploadAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      await GroupsRepository.instance.uploadGroupAvatar(groupId: widget.group.id, file: File(picked.path));
      if (!mounted) return;
      setState(() {
        _avatarUrl = picked.path;
        _uploadingAvatar = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Group photo updated")));
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't upload photo: $e")));
    }
  }

  Future<void> _pickAndUploadCover() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _uploadingCover = true);
    try {
      await GroupsRepository.instance.uploadGroupCover(groupId: widget.group.id, file: File(picked.path));
      if (!mounted) return;
      setState(() {
        _coverUrl = picked.path;
        _uploadingCover = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cover photo updated")));
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingCover = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't upload cover photo: $e")));
    }
  }

  bool _isLocalPath(String? path) => path != null && !path.startsWith("http");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.jetBlack,
        title: Text("Photo & Cover Photo", style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.jetBlack)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text("Cover Photo", style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.jetBlack)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 6,
                child: Container(
                  color: const Color(0xFFF5EFD9),
                  child: _coverUrl == null || _coverUrl!.isEmpty
                      ? const Icon(Icons.image_outlined, color: AppColors.greyShade400, size: 32)
                      : _isLocalPath(_coverUrl)
                          ? Image.file(File(_coverUrl!), fit: BoxFit.cover)
                          : CachedNetworkImage(imageUrl: _coverUrl!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 10),
            PressablePill(
              label: "Change Cover Photo",
              icon: Icons.image_outlined,
              onTap: _uploadingCover ? null : _pickAndUploadCover,
              loading: _uploadingCover,
              filled: false,
            ),
            const SizedBox(height: 28),
            Text("Group Photo", style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.jetBlack)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: SizedBox(
                width: 96,
                height: 96,
                child: Container(
                  color: const Color(0xFFF5EFD9),
                  child: _avatarUrl == null || _avatarUrl!.isEmpty
                      ? const Icon(Icons.groups_outlined, color: AppColors.greyShade400, size: 32)
                      : _isLocalPath(_avatarUrl)
                          ? Image.file(File(_avatarUrl!), fit: BoxFit.cover)
                          : CachedNetworkImage(imageUrl: _avatarUrl!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 10),
            PressablePill(
              label: "Change Group Photo",
              icon: Icons.groups_outlined,
              onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
              loading: _uploadingAvatar,
              filled: false,
            ),
          ],
        ),
      ),
    );
  }
}
