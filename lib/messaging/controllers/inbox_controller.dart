import 'package:flutter/foundation.dart';

import '../models/message_thread_model.dart';
import '../repositories/messaging_repository.dart';

class InboxController extends ChangeNotifier {
  final MessagingRepository _repo = MessagingRepository.instance;

  List<MessageThread> _threads = [];
  String _query = "";
  bool loading = true;
  String? error;

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
      notifyListeners();
    }
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }
}
