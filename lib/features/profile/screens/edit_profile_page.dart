import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';
import 'package:k54_mobile/features/profile/screens/change_profile_photo_page.dart';
import 'package:k54_mobile/features/profile/widgets/profile_fields_form.dart';

/// Matches the K54 Figma file's Edit Profile screen exactly (node
/// 310:1875, rendered 2026-07-08).
///
/// Per the confirmed-backend-first rule: First/Last Name (xprofile fields
/// 1/2) and Bio (field 17) are plain text fields with a confirmed write
/// shape (PUT /xprofile/{fieldId}/data/{userId}, {"value": ...}) - same
/// method also used by ProfileSetup - so Save writes them for real.
/// Username is shown read-only (confirmed non-editable via xprofile -
/// it's set once at signup). Email is shown read-only too; changing it
/// has its own dedicated, already-existing flow (ChangeEmailPage), not
/// this form. The rest of the fields (Field/Industry, Professional
/// Status, Date of Birth, Gender, social links) are the shared
/// [ProfileFieldsForm] also used by ProfileSetup - every one of them now
/// has a confirmed write shape too (2026-07-20) and actually saves - see
/// ProfileFieldsForm's and BuddyBossService's doc comments for the
/// per-field specifics (several of them are real gotchas, not plain
/// strings).
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
  final _fields = ProfileFieldsData();

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
      _fields.fieldValue = (fields?["31"]?["value"]?["raw"] ?? "").toString().isEmpty
          ? null
          : fields?["31"]?["value"]?["raw"];
      _fields.professionalStatusValue = (fields?["5"]?["value"]?["raw"] ?? "").toString().isEmpty
          ? null
          : fields?["5"]?["value"]?["raw"];
      // Gender's raw stored value is already the pronoun-prefixed write
      // value (e.g. "his_Male"), not a display name - matches what
      // ProfileFieldsForm's dropdown resolves back to a name via
      // getFieldOptions. See BuddyBossService.getFieldOptions's doc
      // comment.
      _fields.genderValue = (fields?["18"]?["value"]?["raw"] ?? "").toString().isEmpty
          ? null
          : fields?["18"]?["value"]?["raw"];
      _fields.bioController.text = fields?["17"]?["value"]?["raw"] ?? "";

      final dobRaw = fields?["4"]?["value"]?["raw"]?.toString() ?? "";
      if (dobRaw.isNotEmpty) {
        _fields.dateOfBirth = DateTime.tryParse(dobRaw);
      }

      final socialRaw = fields?["13"]?["value"]?["unserialized"];
      if (socialRaw is Map) {
        _fields.facebookController.text = (socialRaw["facebook"] ?? "").toString();
        _fields.linkedinController.text = (socialRaw["linkedIn"] ?? socialRaw["linkedin"] ?? "").toString();
      }
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
    _fields.dispose();
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

      final writes = <Future<void>>[
        _buddyBossService.updateProfileField(userId: userId, fieldId: 1, value: firstName),
        _buddyBossService.updateProfileField(userId: userId, fieldId: 2, value: lastName),
        _buddyBossService.updateProfileField(userId: userId, fieldId: 17, value: _fields.bioController.text.trim()),
      ];

      // Every write shape below is confirmed live (2026-07-20, test-and-
      // revert against this app's own account) - see BuddyBossService's
      // doc comments for each. Fields left unset by the user are skipped
      // rather than overwriting a real saved value with an empty string.
      if (_fields.fieldValue != null) {
        writes.add(_buddyBossService.updateProfileField(userId: userId, fieldId: 31, value: _fields.fieldValue!));
      }
      if (_fields.professionalStatusValue != null) {
        writes.add(_buddyBossService.updateProfileField(userId: userId, fieldId: 5, value: _fields.professionalStatusValue!));
      }
      if (_fields.genderValue != null) {
        writes.add(_buddyBossService.updateProfileField(userId: userId, fieldId: 18, value: _fields.genderValue!));
      }
      if (_fields.dateOfBirth != null) {
        final dob = _fields.dateOfBirth!;
        final formatted = "${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')} 00:00:00";
        writes.add(_buddyBossService.updateProfileField(userId: userId, fieldId: 4, value: formatted));
      }
      if (_fields.facebookController.text.trim().isNotEmpty || _fields.linkedinController.text.trim().isNotEmpty) {
        writes.add(_buddyBossService.updateSocialNetworksField(
          userId: userId,
          fieldId: 13,
          networks: {
            "facebook": _fields.facebookController.text.trim(),
            "linkedIn": _fields.linkedinController.text.trim(),
          },
        ));
      }

      await Future.wait(writes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile saved")),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: GoogleFonts.lato(fontSize: 15, color: AppColors.jetBlack),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.lato(color: AppColors.greyShade600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: AppColors.greyShade300),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: SafeArea(child: Center(child: CircularProgressIndicator(color: AppColors.green))));
    }

    return Scaffold(
      backgroundColor: AppColors.white,
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
                    UserAvatar(imageUrl: _avatarUrl, name: nameController.text, radius: 60),
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
                            color: AppColors.white,
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
              ProfileFieldsForm(data: _fields),
              const SizedBox(height: 10),
              PrimaryButton(
                label: "Save Changes",
                loading: _saving,
                onPressed: _save,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: "Cancel",
                outline: true,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
