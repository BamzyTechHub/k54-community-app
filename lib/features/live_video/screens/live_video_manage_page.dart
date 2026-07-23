import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/features/live_video/widgets/profile_live_video_tab.dart';

/// Full-page wrapper around the real Channel Controls interface (see
/// ProfileLiveVideoTab's doc comment) - opened from Create Post's "Go
/// Live" entry too, per direct tester feedback ("it should also be the
/// same interface users see when they click on to live from the create
/// post page"), instead of that separate still-unbuilt GoLivePage stub.
class LiveVideoManagePage extends StatelessWidget {
  const LiveVideoManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.jetBlack,
        title: Text("Go Live", style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.jetBlack)),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: ProfileLiveVideoTab(),
        ),
      ),
    );
  }
}
