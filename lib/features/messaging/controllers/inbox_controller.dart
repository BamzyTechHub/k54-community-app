import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:k54_mobile/features/messaging/models/message_thread_model.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';

/// The real website polls its inbox for new messages/unread updates while
/// idly sitting on it (confirmed live via HAR capture 2026-07-21 -
/// `better-messages/v1/checkNew`) - this screen previously only ever
/// refreshed on initial load or manual pull-to-refresh, so a message that
/// arrived while just sitting on the inbox never showed up until the next
/// explicit action. `checkNew`'s own response body wasn't captured with
/// content in that HAR (only its size), so rather than guess at an
/// unconfirmed shape, this reuses [MessagingRepository.refreshThreads] -
/// already a fully confirmed response shape - on the same kind of interval
/// to get the identical practical outcome (a live-updating inbox).
class InboxController extends ChangeNotifier {
  final MessagingRepository _repo = MessagingRepository.instance;
  static const _pollInterval = Duration(seconds: 20);

  List<MessageThread> _threads = [];
  String _query = "";
  bool loading = true;
  String? error;
  bool _disposed = false;
  Timer? _pollTimer;

  List<MessageThread> get threads {
    if (_query.trim().isEmpty) return _threads;
    final q = _query.trim().toLowerCase();
    return _threads.where((t) {
      return t.otherUserName.toLowerCase().contains(q) ||
          t.lastMessagePreview.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _threads = await _repo.refreshThreads();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      // refreshThreads()'s await can outlive this controller if the
      // Messages tab was left mid-fetch - same class of bug ChatController
      // guards against, see its load() for the fuller explanation.
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  /// Call from the inbox screen's initState. Silent - no loading spinner,
  /// so a background refresh never interrupts someone mid-scroll or
  /// mid-search the way [load] would.
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _silentRefresh());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _silentRefresh() async {
    try {
      final threads = await _repo.refreshThreads();
      if (_disposed) return;
      _threads = threads;
      notifyListeners();
    } catch (_) {
      // Silent - a background poll failing shouldn't surface an error over
      // whatever's already on screen; the next successful poll (or a
      // manual pull-to-refresh) recovers on its own.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }
}
