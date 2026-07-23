import 'package:flutter/material.dart';

import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/pressable_pill.dart';
import 'package:k54_mobile/features/friends/repositories/friends_repository.dart';
import 'package:k54_mobile/features/members/repositories/members_repository.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
import 'package:k54_mobile/features/messaging/screens/chat_page.dart';
import 'package:k54_mobile/features/profile/screens/edit_profile_page.dart';

/// Matches the K54 Figma file's profile action row (nodes 289:225 and
/// 428:323): own profile shows "Edit" alone; someone else's profile
/// shows Follow / Message / Connect, Message centered between the other
/// two, per direct stakeholder feedback (2026-07-10) - all three equal-
/// weight pill buttons, not a small icon-only Message affordance.
///
/// Follow is real now (2026-07-21) - `POST members/action/{id}` with
/// `{"action":"follow"|"unfollow"}`, confirmed live (test-and-revert
/// against this app's own account) - see MembersRepository.setFollowing.
///
/// Connect used to always show "Connect" regardless of real relationship
/// state (its own `_requestSent` flag only ever flipped true after
/// sending a NEW request in the current session, never initialized from
/// the profile's actual existing friendship) - fixed by reading the real
/// `friendship_status` field (confirmed present on `GET members/{id}`:
/// "is_friend"/"pending"/"not_friends", plus a `friendship_id` for the
/// accept/remove/cancel calls that need it).
class ProfileActions extends StatefulWidget {
  final bool isCurrentUser;
  final String? otherUserId;
  final bool isFollowing;
  final ValueChanged<bool>? onFollowChanged;
  final String friendshipStatus; // "is_friend" | "pending" | "not_friends"
  final String? friendshipId;

  const ProfileActions({
    super.key,
    required this.isCurrentUser,
    this.otherUserId,
    this.isFollowing = false,
    this.onFollowChanged,
    this.friendshipStatus = "not_friends",
    this.friendshipId,
  });

  @override
  State<ProfileActions> createState() => _ProfileActionsState();
}

class _ProfileActionsState extends State<ProfileActions> {
  bool _openingChat = false;
  bool _sendingRequest = false;
  bool _togglingFollow = false;
  late String _friendshipStatus = widget.friendshipStatus;

  @override
  void didUpdateWidget(ProfileActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.otherUserId != widget.otherUserId) {
      _friendshipStatus = widget.friendshipStatus;
    }
  }

  Future<void> _toggleFollow() async {
    final otherUserId = widget.otherUserId;
    if (otherUserId == null || _togglingFollow) return;

    final newValue = !widget.isFollowing;
    setState(() => _togglingFollow = true);
    try {
      await MembersRepository.instance.setFollowing(userId: otherUserId, follow: newValue);
      widget.onFollowChanged?.call(newValue);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't update follow status: $e")),
      );
    } finally {
      if (mounted) setState(() => _togglingFollow = false);
    }
  }

  Future<void> _openMessage() async {
    final otherUserId = widget.otherUserId;
    if (otherUserId == null || _openingChat) return;

    setState(() => _openingChat = true);
    try {
      final thread = await MessagingRepository.instance
          .findOrCreateThreadWith(otherUserId: otherUserId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatPage(threadId: thread.id, thread: thread)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't open chat: $e")));
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  Future<void> _sendConnectRequest() async {
    final otherUserId = widget.otherUserId;
    if (otherUserId == null || _sendingRequest || _friendshipStatus != "not_friends") return;

    setState(() => _sendingRequest = true);
    try {
      await FriendsRepository.instance.sendFriendRequest(otherUserId);
      if (!mounted) return;
      setState(() => _friendshipStatus = "pending");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend request sent")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't send friend request: $e")),
      );
    } finally {
      if (mounted) setState(() => _sendingRequest = false);
    }
  }

  /// Tapping an already-established relationship offers to undo it
  /// rather than doing nothing - "Friends" cancels via [removeFriend],
  /// "Requested" cancels the outgoing request via
  /// [cancelOutgoingRequest]. Both need the real `friendship_id`
  /// (confirmed present on `GET members/{id}` alongside
  /// `friendship_status`), not the other user's id.
  Future<void> _handleExistingRelationshipTap() async {
    final friendshipId = widget.friendshipId;
    if (friendshipId == null || _sendingRequest) return;

    final isFriend = _friendshipStatus == "is_friend";
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: K54Dialog.shape,
        title: Text(isFriend ? "Remove friend" : "Cancel request"),
        content: Text(isFriend
            ? "Remove this connection? You'll need to send a new request to reconnect."
            : "Cancel this pending friend request?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Yes")),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _sendingRequest = true);
    try {
      if (isFriend) {
        await FriendsRepository.instance.removeFriend(friendshipId);
      } else {
        await FriendsRepository.instance.cancelOutgoingRequest(friendshipId);
      }
      if (!mounted) return;
      setState(() => _friendshipStatus = "not_friends");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't update connection: $e")),
      );
    } finally {
      if (mounted) setState(() => _sendingRequest = false);
    }
  }

  /// Real, distinct value confirmed live 2026-07-23 (`GET members/{id}`):
  /// an INCOMING request (they sent it to you) comes back as
  /// "awaiting_response", not "pending" - a different string from the
  /// OUTGOING case, which is real "pending". Previously unhandled, so an
  /// incoming request silently fell through to the default "Connect"
  /// label - tapping it would have tried to send a second, duplicate
  /// request rather than offering to accept/reject the real one already
  /// waiting (direct tester feedback: "if he is the one that sent me
  /// request it should also show").
  Future<void> _handleIncomingRequestTap() async {
    final friendshipId = widget.friendshipId;
    if (friendshipId == null || _sendingRequest) return;

    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: K54Dialog.shape,
        title: const Text("Friend request"),
        content: const Text("This person sent you a friend request."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, "reject"),
            child: const Text("Decline"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, "accept"),
            child: const Text("Accept"),
          ),
        ],
      ),
    );
    if (action == null) return;

    setState(() => _sendingRequest = true);
    try {
      if (action == "accept") {
        await FriendsRepository.instance.acceptRequest(friendshipId);
        if (!mounted) return;
        setState(() => _friendshipStatus = "is_friend");
      } else {
        await FriendsRepository.instance.rejectRequest(friendshipId);
        if (!mounted) return;
        setState(() => _friendshipStatus = "not_friends");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't update friend request: $e")),
      );
    } finally {
      if (mounted) setState(() => _sendingRequest = false);
    }
  }

  Widget _pillButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool filled = true,
    bool loading = false,
  }) {
    return Expanded(
      child: PressablePill(
        label: label,
        icon: icon,
        onTap: onTap,
        filled: filled,
        loading: loading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCurrentUser) {
      return Row(
        children: [
          _pillButton(
            label: "Edit",
            icon: Icons.edit,
            filled: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        _pillButton(
          label: widget.isFollowing ? "Following" : "Follow",
          icon: widget.isFollowing ? Icons.check : Icons.thumb_up_alt_outlined,
          filled: widget.isFollowing,
          loading: _togglingFollow,
          onTap: _togglingFollow ? null : _toggleFollow,
        ),
        const SizedBox(width: 10),
        _pillButton(
          label: "Message",
          icon: Icons.chat_bubble_outline,
          filled: false,
          loading: _openingChat,
          onTap: _openingChat ? null : _openMessage,
        ),
        const SizedBox(width: 10),
        _pillButton(
          label: switch (_friendshipStatus) {
            "is_friend" => "Friends",
            "pending" => "Requested",
            "awaiting_response" => "Respond",
            _ => "Connect",
          },
          icon: switch (_friendshipStatus) {
            "not_friends" => Icons.person_add_alt_1,
            "awaiting_response" => Icons.mark_email_unread_outlined,
            _ => Icons.check,
          },
          filled: _friendshipStatus != "not_friends",
          loading: _sendingRequest,
          onTap: switch (_friendshipStatus) {
            "not_friends" => _sendConnectRequest,
            "awaiting_response" => _handleIncomingRequestTap,
            _ => _handleExistingRelationshipTap,
          },
        ),
      ],
    );
  }
}
