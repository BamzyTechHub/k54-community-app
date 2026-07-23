import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/features/home/screens/home_page.dart';
import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/features/profile/widgets/profile_fields_form.dart';

/// Post-signup onboarding step. Shares its xprofile field inputs (Field/
/// Industry, Professional Status, Date of Birth, Gender, Bio, social
/// links) with EditProfilePage via [ProfileFieldsForm] rather than
/// maintaining a second hand-built copy - every field now has a confirmed
/// write shape and actually saves, see ProfileFieldsForm's doc comment.
class ProfileSetup extends StatefulWidget {
  const ProfileSetup({super.key});

  @override
  State<ProfileSetup> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetup> {
  final AuthService authService = AuthService();
  final BuddyBossService buddyBossService = BuddyBossService();

  bool isSaving = false;

  final TextEditingController usernameController = TextEditingController();
  final _fields = ProfileFieldsData();

  @override
  void dispose() {
    usernameController.dispose();
    _fields.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username cannot be empty")),
      );
      return;
    }
    if (usernameController.text.contains(" ")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username cannot contain spaces")),
      );
      return;
    }

    setState(() => isSaving = true);
    try {
      // Username is set at signup (registration's field_3) and isn't
      // editable via xprofile, so it's validated above but never re-sent
      // here. Every other field's write shape is confirmed - see
      // ProfileFieldsForm's and BuddyBossService's doc comments.
      final user = await authService.getCurrentUser();
      final userId = user.data["id"].toString();

      final writes = <Future<void>>[
        buddyBossService.updateProfileField(userId: userId, fieldId: 17, value: _fields.bioController.text.trim()),
      ];
      if (_fields.fieldValue != null) {
        writes.add(buddyBossService.updateProfileField(userId: userId, fieldId: 31, value: _fields.fieldValue!));
      }
      if (_fields.professionalStatusValue != null) {
        writes.add(buddyBossService.updateProfileField(userId: userId, fieldId: 5, value: _fields.professionalStatusValue!));
      }
      if (_fields.genderValue != null) {
        writes.add(buddyBossService.updateProfileField(userId: userId, fieldId: 18, value: _fields.genderValue!));
      }
      if (_fields.dateOfBirth != null) {
        final dob = _fields.dateOfBirth!;
        final formatted = "${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')} 00:00:00";
        writes.add(buddyBossService.updateProfileField(userId: userId, fieldId: 4, value: formatted));
      }
      if (_fields.facebookController.text.trim().isNotEmpty || _fields.linkedinController.text.trim().isNotEmpty) {
        writes.add(buddyBossService.updateSocialNetworksField(
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save profile: $e")));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 25),
                Image.asset("assets/images/k54_logo.png", width: 120),
                const SizedBox(height: 25),
                Text(
                  usernameController.text.isEmpty ? "Welcome!" : "Welcome ${usernameController.text}!",
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Kindly setup your profile",
                  style: TextStyle(color: AppColors.grey, fontSize: 15),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: usernameController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: "Create username",
                    hintText: "NO SPACES ALLOWED",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 15),
                ProfileFieldsForm(data: _fields),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: "Save and Continue",
                  loading: isSaving,
                  onPressed: _save,
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFF008000), width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        "Go Back",
                        style: TextStyle(color: Color(0xFF008000), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
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
