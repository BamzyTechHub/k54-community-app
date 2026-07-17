import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';

/// Matches the K54 Figma file's profile header exactly (measured +
/// rendered via the Figma REST API, node 289:225 "PROFILE PAGE/TIMELINE"
/// and node 428:323 "ACCOUNT SETTINGS", 2026-07-08) - centered avatar,
/// name, tagline. No cover banner and no email shown, unlike the
/// previous implementation.
class ProfileHeader extends StatelessWidget {
  final String userName;
  final String userTitle;
  final String userImage;

  const ProfileHeader({
    super.key,
    required this.userName,
    required this.userTitle,
    required this.userImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = userImage.isNotEmpty;
    final ImageProvider? imageProvider = !hasImage
        ? null
        : userImage.startsWith("http")
            ? NetworkImage(userImage)
            : AssetImage(userImage);

    return Column(
      children: [
        UserAvatar(imageUrl: null, imageProvider: imageProvider, name: userName, radius: 50),
        const SizedBox(height: 10),
        Text(
          userName,
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.jetBlack,
          ),
        ),
        if (userTitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            userTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
