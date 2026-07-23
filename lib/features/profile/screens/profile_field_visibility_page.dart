import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/state_views.dart';
import 'package:k54_mobile/features/profile/models/account_settings_field.dart';
import 'package:k54_mobile/features/profile/repositories/account_settings_repository.dart';

/// Real, live per-xprofile-field visibility settings - confirmed live
/// 2026-07-20 via `GET/POST /buddyboss/v1/account-settings/profile`
/// (test-and-revert against this app's own account). This is what
/// BuddyBoss's own real "Privacy" account-settings section actually
/// contains: one Public/All Members/My Connections/Only Me choice per
/// profile field (First Name, Last Name, Username, Field/Industry,
/// Professional Status, Birth Date, Gender, Biography, Social Media) -
/// not the broader Figma-mocked categories PrivacySettingsPage shows
/// (Last Seen, Who Can Message Me, etc.), which have no backend
/// equivalent found anywhere in the site's REST surface. Each dropdown
/// saves immediately on change (matching the app's join/leave/pin-style
/// instant-save pattern elsewhere), not behind a separate Save button.
class ProfileFieldVisibilityPage extends StatefulWidget {
  const ProfileFieldVisibilityPage({super.key});

  @override
  State<ProfileFieldVisibilityPage> createState() => _ProfileFieldVisibilityPageState();
}

class _ProfileFieldVisibilityPageState extends State<ProfileFieldVisibilityPage> {
  static const _nav = "profile";

  List<AccountSettingsField>? _fields;
  bool _loading = true;
  Object? _error;
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fields = await AccountSettingsRepository.instance.getSection(_nav);
      if (!mounted) return;
      setState(() {
        _fields = fields;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _saveField(AccountSettingsField field, String newValue) async {
    setState(() => _saving.add(field.name));
    try {
      final updated = await AccountSettingsRepository.instance.saveSection(_nav, {field.name: newValue});
      if (!mounted) return;
      setState(() {
        _fields = updated;
        _saving.remove(field.name);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving.remove(field.name));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't update ${field.label}: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Profile Visibility",
                    style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Choose who can see each part of your profile.",
                style: GoogleFonts.lato(fontSize: 13, color: AppColors.greyShade600),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_error != null || _fields == null) {
      return K54ErrorState(message: "Couldn't load visibility settings.\n$_error", onRetry: _load);
    }

    return ListView.builder(
      itemCount: _fields!.length,
      itemBuilder: (context, index) {
        final field = _fields![index];
        if (field.isSectionHeader) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              field.headline,
              style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.greyShade700),
            ),
          );
        }
        if (field.options.isEmpty) return const SizedBox.shrink();

        final isSaving = _saving.contains(field.name);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(field.label, style: GoogleFonts.lato(fontSize: 15, color: AppColors.jetBlack)),
              ),
              if (isSaving)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green))
              else
                DropdownButton<String>(
                  value: field.options.containsKey(field.value) ? field.value : null,
                  underline: const SizedBox.shrink(),
                  style: GoogleFonts.lato(fontSize: 14, color: AppColors.jetBlack),
                  items: field.options.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) _saveField(field, value);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
