/// One entry from a real `/buddyboss/v1/account-settings/{nav}` response -
/// see AccountSettingsApiService's doc comment. Section headers come back
/// as an entry with only [headline] set; real settings either stand alone
/// (a `select` field, e.g. per-xprofile-field visibility) or carry
/// [subfields] (a notification type's Email/Web checkbox pair).
class AccountSettingsField {
  final String name;
  final String label;
  final String type;
  final String value;
  final Map<String, String> options;
  final String headline;
  final List<AccountSettingsField> subfields;

  const AccountSettingsField({
    required this.name,
    required this.label,
    required this.type,
    required this.value,
    required this.options,
    required this.headline,
    required this.subfields,
  });

  bool get isSectionHeader => headline.isNotEmpty && name.isEmpty;

  factory AccountSettingsField.fromJson(Map<String, dynamic> json) {
    final rawOptions = json["options"];
    final options = <String, String>{};
    if (rawOptions is Map) {
      rawOptions.forEach((k, v) => options[k.toString()] = v.toString());
    }
    final rawSubfields = json["subfields"];
    return AccountSettingsField(
      name: (json["name"] ?? "").toString(),
      label: (json["label"] ?? "").toString(),
      type: (json["type"] ?? "").toString(),
      value: (json["value"] ?? "").toString(),
      options: options,
      headline: (json["headline"] ?? "").toString(),
      subfields: rawSubfields is List
          ? rawSubfields.whereType<Map>().map((f) => AccountSettingsField.fromJson(Map<String, dynamic>.from(f))).toList()
          : const [],
    );
  }
}
