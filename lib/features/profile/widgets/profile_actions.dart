import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/features/friends/repositories/friends_repository.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
import 'package:k54_mobile/features/messaging/screens/chat_page.dart';
import 'package:k54_mobile/features/profile/screens/edit_profile_page.dart';

/// Matches the K54 Figma file's profile action row (nodes 289:225 and
/// 428:323, rendered 2026-07-08): own profile shows "Edit" alone;
/// someone else's profile shows "Follow" + "Connect". Figma's row has no
/// messaging affordance at all, but removing the app's real, working
/// messaging integration to match that exactly would be a functional
/// regression - so a small icon-only Message button is appended after
/// Connect instead, clearly a deliberate addition rather than an
/// oversight. Flagged for a follow-up decision on where messaging should
/// really live in this row once that's worth revisiting with Figma.
class ProfileActions extends StatefulWidget {
  final bool isCurrentUser;
  final String? otherUserId;

  const ProfileActions({
    super.key,
    required this.isCurrentUser,
    this.otherUserId,
  });

  @override
  State<ProfileActions> createState() => _ProfileActionsState();
}

class _ProfileActionsState extends State<ProfileActions> {
  bool _openingChat = false;
  bool _sendingRequest = false;

  void _comingSoon(String feature) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature is coming soon")),
    );
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
    if (otherUserId == null || _sendingRequest) return;

    setState(() => _sendingRequest = true);
    try {
      await FriendsRepository.instance.sendFriendRequest(otherUserId);
      _comingSoon("Sending friend requests");
    } catch (e) {
      _comingSoon("Sending friend requests");
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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: filled ? AppColors.brandGradient : null,
            border: filled ? null : Border.all(color: AppColors.green, width: 1.5),
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: filled ? Colors.white : AppColors.green,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 16, color: filled ? Colors.white : AppColors.green),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: filled ? Colors.white : AppColors.green,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
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
          label: "Follow",
          icon: Icons.thumb_up_alt_outlined,
          onTap: () => _comingSoon("Following members"),
        ),
        const SizedBox(width: 10),
        _pillButton(
          label: "Connect",
          icon: Icons.person_add_alt_1,
          loading: _sendingRequest,
          onTap: _sendConnectRequest,
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _openingChat ? null : _openMessage,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green, width: 1.5),
            ),
            child: Center(
              child: _openingChat
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.green),
            ),
          ),
        ),
      ],
    );
  }
}
