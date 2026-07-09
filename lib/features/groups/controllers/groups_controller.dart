import 'package:flutter/foundation.dart';

import 'package:k54_mobile/features/groups/models/group_model.dart';
import 'package:k54_mobile/features/groups/repositories/groups_repository.dart';

/// Drives the "All Groups" tab: loading/error/empty, search, page-based
/// infinite scroll - mirrors MembersController/FriendsListController.
class GroupsController extends ChangeNotifier {
  final GroupsRepository _repo = GroupsRepository.instance;

  List<Group> _groups = [];
  String _query = "";
  String _orderby = "last_activity";
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  String? error;
  int? totalCount;
  int _page = 1;
  bool _disposed = false;

  List<Group> get groups => _groups;
  String get orderby => _orderby;

  Future<void> load({String? search}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _query = search ?? _query;
      final result = await _repo.getGroups(search: _query, orderby: _orderby, order: "desc", page: 1);
      _groups = result.groups;
      totalCount = result.total;
      _page = 1;
      hasMore = result.groups.isNotEmpty;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore || loading) return;
    loadingMore = true;
    notifyListeners();
    try {
      final next = await _repo.getGroups(
        search: _query,
        orderby: _orderby,
        order: "desc",
        page: _page + 1,
      );
      if (next.groups.isEmpty) {
        hasMore = false;
      } else {
        _page += 1;
        _groups = [..._groups, ...next.groups];
      }
    } catch (_) {
      // Silent failure on a background page load, matching this app's
      // other paginated lists.
    } finally {
      loadingMore = false;
      if (!_disposed) notifyListeners();
    }
  }

  void search(String query) => load(search: query);

  void sortBy(String orderby) {
    _orderby = orderby;
    load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Drives the "My Groups" tab.
class MyGroupsController extends ChangeNotifier {
  final GroupsRepository _repo = GroupsRepository.instance;

  List<Group> groups = [];
  bool loading = true;
  String? error;
  bool _disposed = false;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      groups = await _repo.getMyGroups();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
