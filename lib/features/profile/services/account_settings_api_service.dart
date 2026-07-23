import 'package:dio/dio.dart';
import 'package:k54_mobile/core/services/api_service.dart';

/// Real BuddyBoss "Account Settings" REST surface - confirmed live
/// 2026-07-20 (test-and-revert against this app's own test account, see
/// docs/api-audit). `GET /buddyboss/v1/account-settings` lists every real
/// settings section (nav slug); `GET/POST .../account-settings/{nav}`
/// reads/writes one section's fields. Two navs are wired so far:
/// `notifications` (per-notification-type email/web toggles, ~20 real
/// keys) and `profile` (per-xprofile-field visibility: Public/All
/// Members/My Connections/Only Me). Both share the identical field/save
/// shape, so one service covers both.
class AccountSettingsApiService {
  final ApiService _api = ApiService.instance;

  Future<Response> getSection(String nav) {
    return _api.get("/buddyboss/v1/account-settings/$nav");
  }

  /// [updates] is field-name -> new value (e.g. `{"enable_notification":
  /// "yes"}` or `{"field_31": "public"}`). Confirmed live: the real
  /// request body is `{"fields": [{"name": ..., "value": ...}, ...]}`,
  /// and the response is the full refreshed section (same shape as GET).
  Future<Response> saveSection(String nav, Map<String, String> updates) {
    return _api.post("/buddyboss/v1/account-settings/$nav", {
      "fields": updates.entries.map((e) => {"name": e.key, "value": e.value}).toList(),
    });
  }
}
