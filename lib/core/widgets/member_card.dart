import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';

/// Matches the "member comp" card from the K54 Figma file (used on both
/// the Members screen, node 55:1914, and the Profile/My Connections tab,
/// node 313:3032) - avatar, name, and a 5-icon action row. Shared here so
/// both screens render the exact same component instead of two copies.
///
/// The connect icon reflects real relationship status now (was always the
/// same static icon regardless of state) - confirmed live 2026-07-24
/// against the real website's own member card, which swaps that icon's
/// tooltip between "Connect" and "Remove Connection" depending on the
/// real relationship, exactly matching [friendshipStatus]'s real values
/// ("not_friends"/"pending"/"awaiting_response"/"is_friend" - see
/// ProfileActions' doc comment for where those were confirmed). A card
/// for the current user's own account ([isCurrentUser]) hides the action
/// row entirely, since none of block/connect/message/call apply to
/// yourself - direct tester feedback that "my own card doesn't show as
/// others do" (it showed the same 5 icons as everyone else's card).
class MemberCard extends StatelessWidget {
  final String id;
  final String name;
  final String? avatarUrl;
  final VoidCallback onTap;
  final VoidCallback onBlock;
  final VoidCallback onConnect;
  final VoidCallback onMessage;
  final VoidCallback onCall;
  final VoidCallback onVideoCall;
  final String friendshipStatus;
  final bool isCurrentUser;

  const MemberCard({
    super.key,
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.onTap,
    required this.onBlock,
    required this.onConnect,
    required this.onMessage,
    required this.onCall,
    required this.onVideoCall,
    this.friendshipStatus = "not_friends",
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    // The tap-to-open-profile area and the action-row buttons used to
    // share one outer TapScale wrapping the whole card, with each action
    // icon as its own nested TapScale inside it - two tap-recognizing
    // GestureDetector/InkWell pairs stacked on top of each other. Nested
    // gesture detectors like that don't reliably resolve in the inner
    // widget's favor (a real, confirmed cause of "most of the buttons
    // aren't functioning" - direct tester feedback), so the outer tap
    // area is now scoped to only the avatar/name section, leaving the
    // action row as a sibling with no ancestor GestureDetector competing
    // for the same taps.
    return Container(
      decoration: BoxDecoration(
        // Exact colors from the MEMBERS Figma frame (node 55:1914,
        // "members comp"), pulled via the REST API 2026-07-16 - was
        // the tan/sage-green pair (groupCardBackground/groupCardAccent)
        // before this measurement existed.
        color: const Color(0xFFFCF8ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB4D69E)),
      ),
      // Container's own clipBehavior wasn't reliably rounding the white
      // action-row strip's bottom corners in practice (they poked out
      // past the border, leaving visible square notches) - an explicit
      // ClipRRect, inset 1px to sit just inside the border stroke,
      // fixes it deterministically instead of depending on Container's
      // decoration-clip behavior.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          children: [
            TapScale(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  children: [
                    UserAvatar(imageUrl: avatarUrl, name: name, radius: 40),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
                    ),
                  ],
                ),
              ),
            ),
            if (!isCurrentUser)
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.green)),
                ),
                child: Row(
                  children: [
                    _action(Icons.block_outlined, onBlock, tooltip: "Block"),
                    _action(_connectIcon(), onConnect, tooltip: _connectTooltip()),
                    _action(Icons.chat_bubble_outline, onMessage, tooltip: "Message"),
                    _action(Icons.call_outlined, onCall, tooltip: "Voice call"),
                    _action(Icons.videocam_outlined, onVideoCall, tooltip: "Video call"),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _connectIcon() {
    switch (friendshipStatus) {
      case "is_friend":
        return Icons.person_remove_outlined;
      case "pending":
        return Icons.hourglass_top_outlined;
      case "awaiting_response":
        return Icons.mark_email_unread_outlined;
      default:
        return Icons.person_add_alt_1_outlined;
    }
  }

  String _connectTooltip() {
    switch (friendshipStatus) {
      case "is_friend":
        return "Remove Connection";
      case "pending":
        return "Requested";
      case "awaiting_response":
        return "Respond";
      default:
        return "Connect";
    }
  }

  Widget _action(IconData icon, VoidCallback onTap, {required String tooltip}) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: TapScale(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.green, width: 0.5)),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF7E7D7D)),
          ),
        ),
      ),
    );
  }
}
