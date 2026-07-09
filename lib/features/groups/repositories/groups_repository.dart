import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/features/groups/models/group_model.dart';
import 'package:k54_mobile/features/groups/services/groups_api_service.dart';

class GroupsRepository {
  GroupsRepository._internal();
  static final GroupsRepository instance = GroupsRepository._internal();

  final GroupsApiService _api = GroupsApiService();
  final AuthService _authService = AuthService();

  String? _cachedUserId;

  Future<String> currentUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;
    final response = await _authService.getCurrentUser();
    _cachedUserId = (response.data['id'] ?? '').toString();
    return _cachedUserId!;
  }

  List<Group> _parseGroups(dynamic data) {
    final List raw = data is List ? data : const [];
    return raw.whereType<Map>().map((g) => Group.fromBuddyBoss(Map<String, dynamic>.from(g))).toList();
  }

  /// [total] comes from WordPress REST's standard `X-WP-Total` header.
  Future<({List<Group> groups, int? total})> getGroups({
    String? search,
    String? orderby,
    String? order,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _api.getGroups(
      search: search,
      orderby: orderby,
      order: order,
      page: page,
      perPage: perPage,
    );
    final totalHeader = response.headers.value("x-wp-total");
    return (
      groups: _parseGroups(response.data),
      total: totalHeader != null ? int.tryParse(totalHeader) : null,
    );
  }

  Future<List<Group>> getMyGroups() async {
    final response = await _api.getMyGroups();
    return _parseGroups(response.data);
  }

  Future<Group> createGroup({
    required String name,
    required String description,
    required String status,
  }) async {
    final response = await _api.createGroup(name: name, description: description, status: status);
    return Group.fromBuddyBoss(Map<String, dynamic>.from(response.data));
  }

  Future<void> joinGroup(String groupId) async {
    final userId = await currentUserId();
    await _api.joinGroup(groupId: groupId, userId: userId);
  }

  Future<void> leaveGroup(String groupId) async {
    final userId = await currentUserId();
    await _api.leaveGroup(groupId: groupId, userId: userId);
  }
}
