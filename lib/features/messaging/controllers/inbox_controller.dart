import 'package:flutter/foundation.dart';

import 'package:k54_mobile/features/messaging/models/message_thread_model.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';

class InboxController extends ChangeNotifier {
  final MessagingRepository _repo = MessagingRepository.instance;

  List<MessageThread> _threads = [];
  String _query = "";
  bool loading = true;
  String? error;
  bool _disposed = false;

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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
