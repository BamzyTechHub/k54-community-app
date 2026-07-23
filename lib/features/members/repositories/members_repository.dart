import 'package:k54_mobile/features/members/models/member_model.dart';
import 'package:k54_mobile/features/members/services/members_api_service.dart';

class MembersRepository {
  MembersRepository._internal();
  static final MembersRepository instance = MembersRepository._internal();

  final MembersApiService _api = MembersApiService();

  /// [total] comes from WordPress REST's standard `X-WP-Total` response
  /// header (present on every collection endpoint, core to WP-JSON, not
  /// BuddyBoss-specific) - null if the header is missing rather than
  /// guessed at.
  Future<({List<Member> members, int? total})> getMembers({
    String? search,
    String? type,
    String? scope,
    String? userId,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _api.getMembers(
      search: search,
      type: type,
      scope: scope,
      userId: userId,
      page: page,
      perPage: perPage,
    );
    final List raw = response.data is List ? response.data : const [];
    final members = raw
        .whereType<Map>()
        .map((m) => Member.fromBuddyBoss(Map<String, dynamic>.from(m)))
        .toList();
    final totalHeader = response.headers.value("x-wp-total");
    return (members: members, total: totalHeader != null ? int.tryParse(totalHeader) : null);
  }

  Future<Member> setFollowing({required String userId, required bool follow}) async {
    final response = await _api.followAction(userId: userId, follow: follow);
    final data = response.data is Map ? response.data["data"] : null;
    return Member.fromBuddyBoss(Map<String, dynamic>.from(data ?? {"id": userId}));
  }
}
