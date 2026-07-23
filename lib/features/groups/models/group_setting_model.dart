/// BuddyBoss's group settings API (`GET/POST buddyboss/v1/groups/{id}/settings
/// ?nav=edit-details|group-settings|forum`) is fully self-describing - confirmed
/// live 2026-07-22 via the route's own OPTIONS schema and real data from a real
/// group: each entry names its own field, input type, current value, and (for
/// choice-based types) its own options - rather than a fixed set of named
/// fields this app would have to hardcode and keep in sync by hand.
class GroupSettingOption {
  final String label;
  final dynamic value;
  final String description;
  final bool isDefault;

  const GroupSettingOption({
    required this.label,
    required this.value,
    required this.description,
    required this.isDefault,
  });

  factory GroupSettingOption.fromJson(Map<String, dynamic> json) {
    return GroupSettingOption(
      label: (json['label'] ?? '').toString(),
      value: json['value'],
      description: (json['description'] ?? '').toString(),
      isDefault: json['is_default_option'] == true || json['is_default_option'] == 1,
    );
  }
}

/// [type] is one of "text"/"textarea"/"checkbox"/"radio"/"select"/"heading" -
/// confirmed real values seen live across edit-details/group-settings/forum.
class GroupSetting {
  final String label;
  final String name;
  final String description;
  final String type;
  final dynamic value;
  final List<GroupSettingOption> options;

  const GroupSetting({
    required this.label,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    required this.options,
  });

  factory GroupSetting.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return GroupSetting(
      label: (json['label'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      type: (json['type'] ?? 'text').toString(),
      value: json['value'],
      options: rawOptions is List
          ? rawOptions.whereType<Map>().map((o) => GroupSettingOption.fromJson(Map<String, dynamic>.from(o))).toList()
          : const [],
    );
  }
}
