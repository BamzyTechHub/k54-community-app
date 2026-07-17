import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';

/// The "list row" shape used by Friends, Groups (embedded tab), and
/// Messages' inbox - previously 4 separately hand-written copies with
/// drifting avatar radius (24/25/28) and, in two cases, a fallback
/// initial that wasn't uppercased. One widget now owns the shared chrome
/// (background, border, avatar, title); each screen still supplies its
/// own trailing content since that genuinely differs (call/video icons,
/// a member-count icon, a timestamp + unread badge).
class ContactRow extends StatelessWidget {
  final String? avatarUrl;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final TextStyle? titleStyle;
  // Rare case (Messages' pinned-thread icon): a small icon/marker before
  // the title text, on the same line.
  final Widget? titlePrefix;
  // See UserAvatar.isOnline's doc comment - null when the caller has no
  // real presence source for this row.
  final bool? isOnline;

  const ContactRow({
    super.key,
    required this.avatarUrl,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.titleStyle,
    this.titlePrefix,
    this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap ?? () {},
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.friendRowBackground,
          border: Border.all(color: AppColors.friendRowBorder),
        ),
        child: Row(
          children: [
            UserAvatar(imageUrl: avatarUrl, name: title, radius: 25, isOnline: isOnline),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (titlePrefix != null) ...[titlePrefix!, const SizedBox(width: 4)],
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle ??
                              GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // #1A1A1A not grey - matches the Messages frame
                      // (node 43:104) preview text exactly, pulled via
                      // the REST API 2026-07-16.
                      style: GoogleFonts.lato(fontSize: 12, color: AppColors.jetBlack),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
