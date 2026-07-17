import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';

/// Matches the "member comp" card from the K54 Figma file (used on both
/// the Members screen, node 55:1914, and the Profile/My Connections tab,
/// node 313:3032) - avatar, name, and a 5-icon action row. Shared here so
/// both screens render the exact same component instead of two copies.
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
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
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
              Padding(
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
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.green)),
                ),
                child: Row(
                  children: [
                    _action(Icons.thumb_down_outlined, onBlock),
                    _action(Icons.person_add_alt_1_outlined, onConnect),
                    _action(Icons.chat_bubble_outline, onMessage),
                    _action(Icons.call_outlined, onCall),
                    _action(Icons.videocam_outlined, onVideoCall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(IconData icon, VoidCallback onTap) {
    return Expanded(
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
    );
  }
}
