import 'package:dio/dio.dart';
import 'package:k54_mobile/core/services/api_service.dart';

/// Raw HTTP calls for `/buddyboss/v1/members`. The base collection route
/// (list, no search) is the same confirmed endpoint messaging's "New
/// Conversation" picker already calls with a `search` param - this just
/// omits it for the full directory, same page/per_page convention used
/// everywhere else in this app's BuddyBoss calls.
class MembersApiService {
  final ApiService _api = ApiService.instance;

  /// [type] maps to BP-REST's confirmed `type` sort parameter on this
  /// endpoint (active|newest|alphabetical|random|online|popular - see
  /// BP_REST_Members_Endpoint::get_items / developer.buddypress.org).
  Future<Response> getMembers({
    String? search,
    String? type,
    int page = 1,
    int perPage = 20,
  }) {
    return _api.get(
      "/buddyboss/v1/members",
      query: {
        "page": page,
        "per_page": perPage,
        if (search != null && search.isNotEmpty) "search": search,
        if (type != null && type.isNotEmpty) "type": type,
      },
    );
  }
}
