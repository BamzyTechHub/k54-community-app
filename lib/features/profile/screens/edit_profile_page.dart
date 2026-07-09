import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/features/profile/screens/change_profile_photo_page.dart';

/// Matches the K54 Figma file's Edit Profile screen exactly (node
/// 310:1875, rendered 2026-07-08).
///
/// Per the confirmed-backend-first rule: First/Last Name (xprofile fields
/// 1/2) and Bio (field 17) are plain text fields with a confirmed write
/// shape (PUT /xprofile/{fieldId}/data/{userId}, {"value": ...}) - same
/// method already used successfully in profile_setup.dart - so Save
/// writes them for real. Username is shown read-only (confirmed
/// non-editable via xprofile - it's set once at signup). Email is shown
/// read-only too; changing it has its own dedicated, already-existing
/// flow (ChangeEmailPage), not this form. Field/Industry, Professional
/// Status, Date of Birth, Gender (selectbox/gender/datebox types) and
/// Instagram/LinkedIn (the composite "socialnetworks" field) all have
/// confirmed field IDs but no confirmed write payload shape - shown and
/// editable in the UI, validated, but not sent, exactly like
/// profile_setup.dart's same limitation.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final AuthService _authService = AuthService();
  final BuddyBossService _buddyBossService = BuddyBossService();

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final fieldController = TextEditingController();
  final professionalStatusController = TextEditingController();
  final dobController = TextEditingController();
  final genderController = TextEditingController();
  final bioController = TextEditingController();
  final instagramController = TextEditingController();
  final linkedinController = TextEditingController();

  String? _userId;
  String _avatarUrl = "";
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final response = await _authService.getCurrentUser();
      final user = response.data;
      _userId = user["id"]?.toString();
      nameController.text = user["name"] ?? "";
      usernameController.text = user["user_login"] ?? "";
      emailController.text = user["user_email"] ?? "";
      _avatarUrl = user["avatar_urls"]?["full"] ?? user["avatar_urls"]?["thumb"] ?? "";

      final fields = user["xprofile"]?["groups"]?["1"]?["fields"];
      fieldController.text = fields?["31"]?["value"]?["raw"] ?? "";
      professionalStatusController.text = fields?["5"]?["value"]?["raw"] ?? "";
      dobController.text = fields?["4"]?["value"]?["raw"] ?? "";
      genderController.text = fields?["18"]?["value"]?["raw"] ?? "";
      bioController.text = fields?["17"]?["value"]?["raw"] ?? "";
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't load profile: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    fieldController.dispose();
    professionalStatusController.dispose();
    dobController.dispose();
    genderController.dispose();
    bioController.dispose();
    instagramController.dispose();
    linkedinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final userId = _userId;
    if (userId == null || _saving) return;

    setState(() => _saving = true);
    try {
      final fullName = nameController.text.trim();
      final parts = fullName.split(" ");
      final firstName = parts.isNotEmpty ? parts.first : "";
      final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

      await Future.wait([
        _buddyBossService.updateProfileField(userId: userId, fieldId: 1, value: firstName),
        _buddyBossService.updateProfileField(userId: userId, fieldId: 2, value: lastName),
        _buddyBossService.updateProfileField(userId: userId, fieldId: 17, value: bioController.text.trim()),
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Name and bio saved. Field, Professional Status, Date of Birth, "
            "Gender, and social links aren't syncing yet - we're still "
            "confirming how the website expects those.",
          ),
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save profile: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        style: GoogleFonts.lato(fontSize: 15, color: AppColors.jetBlack),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.lato(color: Colors.grey.shade600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: SafeArea(child: Center(child: CircularProgressIndicator())));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                    "Edit Your Profile",
                    style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                      child: _avatarUrl.isEmpty ? const Icon(Icons.person, size: 48) : null,
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangeProfilePhotoPage()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.green, width: 1.5),
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: AppColors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              _field(label: "Full Name", controller: nameController),
              _field(label: "Username/Handle", controller: usernameController, enabled: false),
              _field(label: "Email", controller: emailController, enabled: false),
              _field(label: "Field/ Industry", controller: fieldController),
              _field(label: "Professional Status", controller: professionalStatusController),
              _field(label: "Date of Birth", controller: dobController),
              _field(label: "Gender", controller: genderController),
              _field(label: "Bio", controller: bioController, maxLines: 3),
              _field(label: "Instagram", controller: instagramController),
              _field(label: "LinkedIn", controller: linkedinController),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  height: 55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: AppColors.brandGradient,
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            "Save Changes",
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.green, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.lato(
                        color: AppColors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
