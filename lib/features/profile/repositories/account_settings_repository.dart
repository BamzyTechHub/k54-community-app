import 'package:k54_mobile/features/profile/models/account_settings_field.dart';
import 'package:k54_mobile/features/profile/services/account_settings_api_service.dart';

class AccountSettingsRepository {
  AccountSettingsRepository._internal();
  static final AccountSettingsRepository instance = AccountSettingsRepository._internal();

  final AccountSettingsApiService _api = AccountSettingsApiService();

  List<AccountSettingsField> _parse(dynamic data) {
    final List raw = data is List ? data : const [];
    return raw.whereType<Map>().map((f) => AccountSettingsField.fromJson(Map<String, dynamic>.from(f))).toList();
  }

  Future<List<AccountSettingsField>> getSection(String nav) async {
    final response = await _api.getSection(nav);
    return _parse(response.data);
  }

  Future<List<AccountSettingsField>> saveSection(String nav, Map<String, String> updates) async {
    final response = await _api.saveSection(nav, updates);
    final data = response.data is Map ? response.data["data"] : response.data;
    return _parse(data);
  }
}
