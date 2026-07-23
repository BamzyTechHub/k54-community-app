import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/pressable_pill.dart';
import 'package:k54_mobile/core/widgets/skeleton_loaders.dart';
import 'package:k54_mobile/core/widgets/state_views.dart';
import 'package:k54_mobile/features/groups/models/group_setting_model.dart';
import 'package:k54_mobile/features/groups/repositories/groups_repository.dart';

/// Generic renderer for BuddyBoss's self-describing group settings API (see
/// GroupSetting's doc comment) - one screen handles both the "group-settings"
/// nav (privacy/invite/media-upload permissions, parent group) and the
/// "forum" nav (the discussion-forum enable checkbox), since the real API
/// itself doesn't distinguish them beyond the `nav` parameter and a
/// different list of fields. Building one generic form instead of
/// hand-coding each field name means any setting BuddyBoss adds later
/// renders correctly here too, matching how the real API was designed.
class GroupSettingsPage extends StatefulWidget {
  final String groupId;
  final String nav;
  final String title;

  const GroupSettingsPage({super.key, required this.groupId, required this.nav, required this.title});

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  List<GroupSetting>? _settings;
  final Map<String, dynamic> _values = {};
  final Map<String, dynamic> _changed = {};
  bool _loading = true;
  Object? _error;
  bool _saving = false;

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
      final settings = await GroupsRepository.instance.getGroupSettings(groupId: widget.groupId, nav: widget.nav);
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _values.clear();
        for (final s in settings) {
          _values[s.name] = s.value;
        }
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

  Future<void> _save() async {
    if (_changed.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    try {
      await GroupsRepository.instance.updateGroupSettings(groupId: widget.groupId, nav: widget.nav, fields: _changed);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't save: $e")));
      setState(() => _saving = false);
    }
  }

  void _setValue(String name, dynamic value) {
    setState(() {
      _values[name] = value;
      _changed[name] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.jetBlack,
        title: Text(widget.title, style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.jetBlack)),
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: (_settings != null && _settings!.isNotEmpty)
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PressablePill(
                  label: "Save Changes",
                  onTap: _saving ? null : _save,
                  loading: _saving,
                  height: 48,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(16), child: SkeletonRowList());
    }
    if (_error != null) {
      return K54ErrorState(message: "Couldn't load settings.\n$_error", onRetry: _load);
    }
    final settings = _settings ?? [];
    if (settings.isEmpty) {
      return const K54EmptyState(icon: Icons.settings_outlined, message: "Nothing to configure here yet");
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: settings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (context, index) => _buildField(settings[index]),
    );
  }

  Widget _buildField(GroupSetting setting) {
    switch (setting.type) {
      case 'heading':
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(setting.label, style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.jetBlack)),
              if (setting.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(setting.description, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.greyShade600)),
                ),
            ],
          ),
        );

      case 'checkbox':
        // A single-option checkbox (e.g. the forum toggle) uses its own
        // option's label as the visible text - the setting's own [label]
        // is often empty for this shape (confirmed live: forum toggle).
        final optionLabel = setting.options.isNotEmpty ? setting.options.first.label : setting.label;
        final checked = _values[setting.name] == true || _values[setting.name] == 1 || _values[setting.name] == '1';
        return CheckboxListTile(
          value: checked,
          onChanged: (v) => _setValue(setting.name, v ?? false),
          title: Text(optionLabel, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.jetBlack)),
          subtitle: setting.description.isNotEmpty ? Text(setting.description, style: GoogleFonts.poppins(fontSize: 12)) : null,
          activeColor: AppColors.green,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );

      case 'radio':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(setting.label, style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.jetBlack)),
            if (setting.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: Text(setting.description, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.greyShade600)),
              ),
            for (final option in setting.options)
              RadioListTile<dynamic>(
                value: option.value,
                groupValue: _values[setting.name],
                onChanged: (v) => _setValue(setting.name, v),
                title: Text(option.label, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.jetBlack)),
                activeColor: AppColors.green,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
          ],
        );

      case 'select':
        return DropdownButtonFormField<dynamic>(
          initialValue: setting.options.any((o) => o.value == _values[setting.name]) ? _values[setting.name] : null,
          decoration: InputDecoration(labelText: setting.label),
          items: setting.options
              .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (v) => _setValue(setting.name, v),
        );

      case 'textarea':
        return TextFormField(
          initialValue: (_values[setting.name] ?? '').toString(),
          maxLines: 3,
          decoration: InputDecoration(labelText: setting.label),
          onChanged: (v) => _setValue(setting.name, v),
        );

      default:
        return TextFormField(
          initialValue: (_values[setting.name] ?? '').toString(),
          decoration: InputDecoration(labelText: setting.label),
          onChanged: (v) => _setValue(setting.name, v),
        );
    }
  }
}
