import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';

/// Shared controller/state bundle for the xprofile fields that both
/// ProfileSetup (post-signup onboarding) and EditProfilePage (later
/// editing, from the profile menu) used to duplicate as two separate
/// hand-built forms. All of these map to confirmed xprofile field IDs
/// (Field/Industry=31, Professional Status=5, Date of Birth=4, Gender=18,
/// Bio=17, Social Media=13) - every field's real write shape is now
/// confirmed (2026-07-20, live test-and-revert against this app's own
/// test account - see BuddyBossService's doc comments for each), so
/// Save actually persists all of them now, not just Bio.
///
/// Field/Industry and Professional Status are real `selectbox` fields
/// (not freeform text) - their exact option lists are fetched live rather
/// than hardcoded, so this always matches whatever the site admin has
/// configured. Gender is a `gender`-type field whose options carry a
/// separate pronoun-prefixed write value (e.g. "Male" displays, but
/// "his_Male" is what must be saved - sending the plain name fails with a
/// real 500). Social Media only has Facebook + LinkedIn configured on
/// this site (confirmed via the field's own live `options` list) - no
/// Instagram option exists, so that field was removed rather than kept
/// as a guess that silently wouldn't save anywhere real.
class ProfileFieldsData {
  /// Selected option's *display name* for Field/Industry and Professional
  /// Status (selectbox fields - name IS the save value for these).
  String? fieldValue;
  String? professionalStatusValue;

  /// Selected option's *write* value for Gender (e.g. "his_Male") - kept
  /// separate from the display name shown in the dropdown.
  String? genderValue;

  final bioController = TextEditingController();
  final facebookController = TextEditingController();
  final linkedinController = TextEditingController();
  DateTime? dateOfBirth;

  String get dobDisplay => dateOfBirth == null
      ? ""
      : "${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}";

  void dispose() {
    bioController.dispose();
    facebookController.dispose();
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
  static const _fieldIndustryId = 31;
  static const _professionalStatusId = 5;
  static const _genderId = 18;

  final BuddyBossService _service = BuddyBossService();

  List<XProfileFieldOption>? _fieldIndustryOptions;
  List<XProfileFieldOption>? _professionalStatusOptions;
  List<XProfileFieldOption>? _genderOptions;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([
        _service.getFieldOptions(_fieldIndustryId),
        _service.getFieldOptions(_professionalStatusId),
        _service.getFieldOptions(_genderId),
      ]);
      if (!mounted) return;
      setState(() {
        _fieldIndustryOptions = results[0];
        _professionalStatusOptions = results[1];
        _genderOptions = results[2];
      });
    } catch (_) {
      // Options failed to load - the dropdowns below just show a loading
      // state indefinitely rather than a broken/empty picker; the rest of
      // the form (bio/dob/social) still works independently.
    }
  }

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

  /// [selected] is the display name currently chosen; [onSelected] is
  /// called with the option's own [XProfileFieldOption] (so the caller can
  /// store either .name or .value depending on the field).
  Widget _dropdown({
    required String label,
    required List<XProfileFieldOption>? options,
    required String? selected,
    required ValueChanged<XProfileFieldOption> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        // `initialValue` only applies on this FormField's first build -
        // options (and the existing saved value they let us resolve) load
        // asynchronously after this widget's first frame, so without a key
        // that changes once real data arrives, a pre-existing selection
        // would never visually populate. Forces a fresh FormField state
        // once options go from null -> loaded.
        key: ValueKey("$label-${options != null}"),
        initialValue: options != null && options.any((o) => o.name == selected) ? selected : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.lato(color: AppColors.greyShade600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: AppColors.greyShade300),
          ),
        ),
        hint: options == null ? const Text("Loading...") : Text("Select $label"),
        items: (options ?? [])
            .map((o) => DropdownMenuItem(value: o.name, child: Text(o.name)))
            .toList(),
        onChanged: options == null
            ? null
            : (value) {
                final option = options.firstWhere((o) => o.name == value);
                onSelected(option);
              },
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
        _dropdown(
          label: "Field / Industry",
          options: _fieldIndustryOptions,
          selected: data.fieldValue,
          onSelected: (option) => setState(() => data.fieldValue = option.name),
        ),
        _dropdown(
          label: "Professional Status",
          options: _professionalStatusOptions,
          selected: data.professionalStatusValue,
          onSelected: (option) => setState(() => data.professionalStatusValue = option.name),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greyShade300),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                data.dateOfBirth == null ? "Date of Birth" : data.dobDisplay,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  color: data.dateOfBirth == null ? AppColors.greyShade600 : AppColors.jetBlack,
                ),
              ),
            ),
          ),
        ),
        _dropdown(
          label: "Gender",
          options: _genderOptions,
          // The dropdown itself always displays/selects by name - genderValue
          // (the pronoun-prefixed write value) is looked up from the matching
          // option, not shown directly.
          selected: _genderOptions?.firstWhere(
            (o) => o.value == data.genderValue,
            orElse: () => const XProfileFieldOption(name: "", value: ""),
          ).name,
          onSelected: (option) => setState(() => data.genderValue = option.value),
        ),
        _field(label: "Bio", controller: data.bioController, maxLines: 3),
        if (widget.showSocialLinks) ...[
          _field(label: "Facebook", controller: data.facebookController, prefixIcon: Icons.facebook),
          _field(label: "LinkedIn", controller: data.linkedinController, prefixIcon: Icons.business),
        ],
      ],
    );
  }
}
