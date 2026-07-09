import 'package:flutter/foundation.dart';

import 'package:k54_mobile/features/notifications/models/app_notification.dart';
import 'package:k54_mobile/features/notifications/services/notifications_api_service.dart';

class NotificationsRepository {
  NotificationsRepository._internal();
  static final NotificationsRepository instance = NotificationsRepository._internal();

  final NotificationsApiService _api = NotificationsApiService();
  List<AppNotification> _cached = [];

  /// Mirrors MessagingRepository.unreadCount's pattern - any badge widget
  /// can listen to this directly without a manual refresh call.
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  void _recalculateUnread() {
    unreadCount.value = _cached.where((n) => n.isNew).length;
  }

  Future<List<AppNotification>> getNotifications({int page = 1, int perPage = 20}) async {
    final response = await _api.getNotifications(page: page, perPage: perPage);
    final List raw = response.data is List ? response.data : const [];
    final result = raw
        .whereType<Map>()
        .map((n) => AppNotification.fromBuddyBoss(Map<String, dynamic>.from(n)))
        .toList();
    if (page == 1) {
      _cached = result;
      _recalculateUnread();
    }
    return result;
  }

  Future<void> markRead(String id) async {
    await _api.markRead(id);
    final match = _cached.where((n) => n.id == id);
    if (match.isNotEmpty) match.first.isNew = false;
    _recalculateUnread();
  }

  /// The bulk endpoint's exact request body shape isn't confirmed (only
  /// its existence and purpose are, per BuddyPress's source) - tries it
  /// first, and falls back to marking each notification read individually
  /// via the fully-confirmed single-notification endpoint if it fails,
  /// rather than risk a bulk call that silently does nothing.
  Future<void> markAllRead() async {
    try {
      await _api.markAllRead();
      for (final n in _cached) {
        n.isNew = false;
      }
    } catch (_) {
      for (final n in _cached.where((n) => n.isNew).toList()) {
        try {
          await markRead(n.id);
        } catch (_) {
          // Best-effort - one failing notification shouldn't stop the rest.
        }
      }
    }
    _recalculateUnread();
  }
}
