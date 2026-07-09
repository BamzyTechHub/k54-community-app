import 'package:flutter/material.dart';

/// A BuddyBoss notification, per BuddyPress's open-source BP-REST plugin
/// (class-bp-rest-notifications-endpoint.php on
/// github.com/buddypress/BP-REST) - same evidence-based approach used for
/// Friends/Groups. Confirmed fields: id, user_id, item_id,
/// secondary_item_id, component, action, date, is_new.
///
/// The REST route does NOT return a ready-made display string (unlike
/// the website's own Heartbeat-delivered HTML fragments, which are
/// pre-rendered server-side and aren't structured data this app can
/// reuse) - [displayText] is a generic, honest label derived from
/// [component]/[action] rather than an attempt to reproduce the
/// website's exact copy, which isn't available via this endpoint.
class AppNotification {
  final String id;
  final String itemId;
  final String? secondaryItemId;
  final String component;
  final String action;
  final DateTime date;
  bool isNew;

  AppNotification({
    required this.id,
    required this.itemId,
    this.secondaryItemId,
    required this.component,
    required this.action,
    required this.date,
    required this.isNew,
  });

  factory AppNotification.fromBuddyBoss(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      itemId: (json['item_id'] ?? '').toString(),
      secondaryItemId: json['secondary_item_id']?.toString(),
      component: (json['component'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      isNew: json['is_new'] == true || json['is_new'] == 1,
    );
  }

  /// Best-effort generic label - the exact component/action string
  /// vocabulary BuddyBoss uses beyond "messages"/"activity"/"friends"/
  /// "groups" isn't confirmed, so unrecognized combinations fall back to
  /// a neutral "New notification" rather than guessing specific wording.
  String get displayText {
    switch (component) {
      case 'messages':
        return 'You have a new message';
      case 'activity':
        return action.contains('comment') ? 'Someone commented on your post' : 'New activity on your post';
      case 'friends':
        return 'New friend request';
      case 'groups':
        return 'New group activity';
      default:
        return 'New notification';
    }
  }

  IconData get displayIcon {
    switch (component) {
      case 'messages':
        return Icons.chat_bubble;
      case 'activity':
        return Icons.favorite;
      case 'friends':
        return Icons.person_add;
      case 'groups':
        return Icons.groups;
      default:
        return Icons.notifications;
    }
  }

  Color get displayColor {
    switch (component) {
      case 'messages':
        return Colors.blue;
      case 'activity':
        return Colors.red;
      case 'friends':
        return Colors.green;
      case 'groups':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
