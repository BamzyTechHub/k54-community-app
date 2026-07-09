import 'package:flutter/foundation.dart';

import 'package:k54_mobile/features/members/models/member_model.dart';
import 'package:k54_mobile/features/members/repositories/members_repository.dart';

/// Drives the "All Members" tab: loading/error/empty state, search,
/// and page-based infinite scroll - mirrors FriendsListController's shape.
class MembersController extends ChangeNotifier {
  final MembersRepository _repo = MembersRepository.instance;

  List<Member> _members = [];
  String _query = "";
  String _sortType = "active";
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  String? error;
  int? totalCount;
  int _page = 1;
  bool _disposed = false;

  List<Member> get members => _members;
  String get sortType => _sortType;

  Future<void> load({String? search}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _query = search ?? _query;
      final result = await _repo.getMembers(search: _query, type: _sortType, page: 1);
      _members = result.members;
      totalCount = result.total;
      _page = 1;
      hasMore = result.members.isNotEmpty;
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
      final next = await _repo.getMembers(search: _query, type: _sortType, page: _page + 1);
      if (next.members.isEmpty) {
        hasMore = false;
      } else {
        _page += 1;
        _members = [..._members, ...next.members];
      }
    } catch (_) {
      // Silent failure on a background page load, same convention used
      // throughout this app's other paginated lists.
    } finally {
      loadingMore = false;
      if (!_disposed) notifyListeners();
    }
  }

  void search(String query) {
    load(search: query);
  }

  void sortBy(String type) {
    _sortType = type;
    load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
