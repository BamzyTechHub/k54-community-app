import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';

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
          color: AppColors.groupCardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.groupCardAccent),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: avatarUrl == null || avatarUrl!.isEmpty
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: const TextStyle(fontSize: 24))
                        : null,
                  ),
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
                border: Border(top: BorderSide(color: AppColors.groupCardAccent)),
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
    );
  }

  Widget _action(IconData icon, VoidCallback onTap) {
    return Expanded(
      child: TapScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppColors.groupCardAccent, width: 0.5)),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF7E7D7D)),
        ),
      ),
    );
  }
}
