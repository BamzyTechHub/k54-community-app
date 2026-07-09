import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';

/// Shared controller/state bundle for the xprofile fields that both
/// ProfileSetup (post-signup onboarding) and EditProfilePage (later
/// editing, from the profile menu) used to duplicate as two separate
/// hand-built forms. All of these map to confirmed xprofile field IDs
/// (Field/Industry=31, Professional Status=5, Date of Birth=4, Gender=18,
/// Bio=17) but only Bio has a confirmed write payload shape - the rest
/// are shown/editable and validated, not silently dropped, per the
/// project's "build the UI, don't guess the write format" rule.
///
/// Field/Professional Status/Gender are plain text here rather than the
/// constrained dropdowns ProfileSetup used to guess at (e.g. "Beginner/
/// Intermediate/Advanced/Expert") - those option lists were never
/// confirmed against BuddyBoss's real allowed values, so a fixed dropdown
/// risked excluding a real value. Date of Birth uses a real date picker
/// (an unambiguous UX improvement over a freeform text field regardless
/// of write-format confirmation status).
class ProfileFieldsData {
  final fieldController = TextEditingController();
  final professionalStatusController = TextEditingController();
  final genderController = TextEditingController();
  final bioController = TextEditingController();
  final facebookController = TextEditingController();
  final instagramController = TextEditingController();
  final linkedinController = TextEditingController();
  DateTime? dateOfBirth;

  String get dobDisplay => dateOfBirth == null
      ? ""
      : "${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}";

  void dispose() {
    fieldController.dispose();
    professionalStatusController.dispose();
    genderController.dispose();
    bioController.dispose();
    facebookController.dispose();
    instagramController.dispose();
    linkedinController.dispose();
  }
}

class ProfileFieldsForm extends StatefulWidget {
  final ProfileFieldsData data;
  final bool showSocialLinks;

  const ProfileFieldsForm({super.key, required this.data, this.showSocialLinks = true});

  @override
  State<ProfileFieldsForm> createState() => _ProfileFieldsFormState();
}

class _ProfileFieldsFormState extends State<ProfileFieldsForm> {
  Widget _field({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.lato(fontSize: 15, color: AppColors.jetBlack),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.green) : null,
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDate: widget.data.dateOfBirth ?? DateTime(2000),
    );
    if (picked != null) setState(() => widget.data.dateOfBirth = picked);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(label: "Field / Industry", controller: data.fieldController),
        _field(label: "Professional Status", controller: data.professionalStatusController),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                data.dateOfBirth == null ? "Date of Birth" : data.dobDisplay,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  color: data.dateOfBirth == null ? Colors.grey.shade600 : AppColors.jetBlack,
                ),
              ),
            ),
          ),
        ),
        _field(label: "Gender", controller: data.genderController),
        _field(label: "Bio", controller: data.bioController, maxLines: 3),
        if (widget.showSocialLinks) ...[
          _field(label: "Facebook", controller: data.facebookController, prefixIcon: Icons.facebook),
          _field(label: "Instagram", controller: data.instagramController, prefixIcon: Icons.camera_alt_outlined),
          _field(label: "LinkedIn", controller: data.linkedinController, prefixIcon: Icons.business),
        ],
      ],
    );
  }
}
