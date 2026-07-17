import 'package:flutter/foundation.dart';

import 'package:k54_mobile/features/friends/models/friendship_model.dart';
import 'package:k54_mobile/features/friends/repositories/friends_repository.dart';

/// Drives the Friends list tab: loading/error/empty state, pull-to-refresh,
/// and page-based infinite scroll, mirroring InboxController's shape.
class FriendsListController extends ChangeNotifier {
  final FriendsRepository _repo = FriendsRepository.instance;

  List<Friendship> _friends = [];
  String _query = "";
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  String? error;
  int _page = 1;
  bool _disposed = false;

  List<Friendship> get friends {
    if (_query.trim().isEmpty) return _friends;
    final q = _query.trim().toLowerCase();
    return _friends.where((f) => f.otherUserName.toLowerCase().contains(q)).toList();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _repo.getFriends(page: 1);
      _friends = result;
      _page = 1;
      hasMore = result.isNotEmpty;
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
      final next = await _repo.getFriends(page: _page + 1);
      if (next.isEmpty) {
        hasMore = false;
      } else {
        _page += 1;
        _friends = [..._friends, ...next];
      }
    } catch (_) {
      // Silent failure on a background page load, same convention as
      // TimelinePage/CommentsSheet's own loadMore().
    } finally {
      loadingMore = false;
      if (!_disposed) notifyListeners();
    }
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Drives the Requests tab: incoming + outgoing pending friendships.
/// Accept/reject/cancel call the repository's real REST methods (wired
/// 2026-07-15 - see friends_api_service.dart's doc comment for the
/// field-name caveat) and surface any error as a normal catchable one.
class FriendsRequestsController extends ChangeNotifier {
  final FriendsRepository _repo = FriendsRepository.instance;

  List<Friendship> incoming = [];
  List<Friendship> outgoing = [];
  bool loading = true;
  String? error;
  bool _disposed = false;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _repo.getPendingRequests(page: 1);
      incoming = result.incoming;
      outgoing = result.outgoing;
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
