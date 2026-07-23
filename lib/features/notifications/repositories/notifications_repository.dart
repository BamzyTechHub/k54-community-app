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

  /// Confirmed live 2026-07-23: the real `is_new` arg on this endpoint
  /// defaults to `true`, meaning a plain fetch with no explicit `is_new`
  /// silently returns ONLY unread notifications - the entire read history
  /// (including anything the site's own UI already auto-marked read, e.g.
  /// visiting the Friends/Requests page) was invisible in the app. Real
  /// evidence: a genuine incoming friend-request notification existed
  /// server-side (confirmed via a direct API check) but never appeared in
  /// the app because BuddyBoss had already flipped its `is_new` to 0.
  /// Fetches both states and merges them, newest first, so the list shows
  /// full history like the site does - unread ones are still visually
  /// distinguished via AppNotification.isNew.
  Future<List<AppNotification>> getNotifications({int page = 1, int perPage = 20}) async {
    final results = await Future.wait([
      _api.getNotifications(page: page, perPage: perPage, isNew: true),
      _api.getNotifications(page: page, perPage: perPage, isNew: false),
    ]);

    List<AppNotification> parse(dynamic data) {
      final List raw = data is List ? data : const [];
      return raw
          .whereType<Map>()
          .map((n) => AppNotification.fromBuddyBoss(Map<String, dynamic>.from(n)))
          .toList();
    }

    final merged = [...parse(results[0].data), ...parse(results[1].data)];
    merged.sort((a, b) => b.date.compareTo(a.date));

    if (page == 1) {
      _cached = merged;
      _recalculateUnread();
    }
    return merged;
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
