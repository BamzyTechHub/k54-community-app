import 'package:flutter/foundation.dart';

import 'package:k54_mobile/features/notifications/models/app_notification.dart';
import 'package:k54_mobile/features/notifications/repositories/notifications_repository.dart';

class NotificationsController extends ChangeNotifier {
  final NotificationsRepository _repo = NotificationsRepository.instance;

  List<AppNotification> notifications = [];
  bool loading = true;
  String? error;
  bool _disposed = false;

  int get unreadCount => notifications.where((n) => n.isNew).length;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      notifications = await _repo.getNotifications();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> markRead(AppNotification notification) async {
    if (!notification.isNew) return;
    notification.isNew = false;
    notifyListeners();
    try {
      await _repo.markRead(notification.id);
    } catch (_) {
      notification.isNew = true;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    final previouslyUnread = notifications.where((n) => n.isNew).toList();
    for (final n in notifications) {
      n.isNew = false;
    }
    notifyListeners();
    try {
      await _repo.markAllRead();
    } catch (_) {
      for (final n in previouslyUnread) {
        n.isNew = true;
      }
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
