import 'package:flutter/material.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';

/// The "Continue with Google/Facebook" button - previously hand-coded
/// separately (and near-identically) in both Login and Sign Up.
class SocialButton extends StatelessWidget {
  final String label;
  final String iconAsset;
  final VoidCallback onTap;

  const SocialButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconAsset, width: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.jetBlack),
            ),
          ],
        ),
      ),
    );
  }
}
