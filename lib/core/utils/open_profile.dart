import 'package:flutter/material.dart';

import 'package:k54_mobile/core/utils/k54_route.dart';
import 'package:k54_mobile/features/friends/repositories/friends_repository.dart';
import 'package:k54_mobile/features/profile/screens/profile_page.dart';

/// Opens a user's profile by id, but resolves to the viewer's own profile
/// route (ProfilePage with no userId) when [userId] is the logged-in
/// user's own id. Passing the id through unconditionally makes
/// ProfileActions read it as "someone else's profile" and show Follow/
/// Message/Connect instead of Edit, even for the viewer's own post/comment/
/// card - this is the one path every profile-navigation call site must go
/// through instead of constructing ProfilePage(userId: ...) directly.
Future<void> openProfile(BuildContext context, String userId) async {
  String? targetUserId = userId;
  try {
    final myId = await FriendsRepository.instance.currentUserId();
    if (myId == userId) targetUserId = null;
  } catch (_) {
    // Falls back to treating this as another user's profile - worst case
    // is a wrong action row, not a crash or a dead tap.
  }
  if (!context.mounted) return;
  Navigator.push(context, k54Route(ProfilePage(userId: targetUserId)));
}
