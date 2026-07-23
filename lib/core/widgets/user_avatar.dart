import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';

/// Single source of truth for how a user/member avatar renders app-wide -
/// consolidates what used to be 16 separately hand-written `CircleAvatar`
/// call sites with drifting radii (14-100, no consistent scale) and three
/// incompatible "no photo" fallbacks (uppercased initial / non-uppercased
/// initial / generic person icon / hardcoded placeholder asset). The
/// uppercased-initial fallback was already the majority convention (8 of
/// 9 letter-fallback sites), so that's the one kept here.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  // Rare case (ProfileHeader's own avatar): the source may be a bundled
  // asset path rather than a network URL. When set, this takes priority
  // over [imageUrl].
  final ImageProvider? imageProvider;
  // Optional ring around the avatar - null by default so existing call
  // sites are unaffected. Some Figma frames specify one explicitly (e.g.
  // the Homepage post card's "Ellipse 214": stroke=#FCF8ED
  // strokeWeight=2.0) and some don't (e.g. the header chip avatar) - this
  // is per-call-site, not a global default.
  final Color? borderColor;
  final double borderWidth;
  // Real presence data (Better Messages' users[] carries status.slug -
  // "online"/"offline" - confirmed live, see
  // docs/api-audit/messaging-better-messages.md). Null when the caller has
  // no presence source for this user (e.g. Friends' BuddyBoss-only data) -
  // renders nothing, same "omit rather than fake" rule already applied
  // elsewhere. Only true/false draws the dot.
  final bool? isOnline;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.radius = 22,
    this.imageProvider,
    this.borderColor,
    this.borderWidth = 2,
    this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final provider = imageProvider ??
        (imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null);
    // When bordered, the inner circle shrinks by borderWidth so the total
    // outer size still matches [radius] exactly (border drawn just inside
    // the boundary) rather than growing the avatar past its slot.
    final innerRadius = borderColor == null ? radius : radius - borderWidth;
    final avatar = CircleAvatar(
      radius: innerRadius,
      backgroundColor: AppColors.greyShade200,
      backgroundImage: provider,
      child: provider != null
          ? null
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : "?",
              style: TextStyle(fontSize: innerRadius * 0.55, fontWeight: FontWeight.w600),
            ),
    );

    final bordered = borderColor == null
        ? avatar
        : Container(
            padding: EdgeInsets.all(borderWidth),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor!, width: borderWidth),
            ),
            child: avatar,
          );

    if (isOnline != true) return bordered;

    final dotSize = (radius * 0.32).clamp(6.0, 14.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        bordered,
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: const Color(0xFF46A046),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: dotSize * 0.18),
            ),
          ),
        ),
      ],
    );
  }
}
