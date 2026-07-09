import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';

/// UI-only pre-broadcast screen (Figma's "GO LIVE" frame, node 352:246 -
/// couldn't re-verify pixel details, Figma API is rate-limited). No
/// live-streaming backend is confirmed anywhere in the site's REST
/// surface, so this is an honest placeholder: full UI, no fake success.
class GoLivePage extends StatefulWidget {
  const GoLivePage({super.key});

  @override
  State<GoLivePage> createState() => _GoLivePageState();
}

class _GoLivePageState extends State<GoLivePage> {
  final TextEditingController _titleController = TextEditingController();
  String _privacy = "public";

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Live video isn't available yet")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 26),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Go Live",
                    style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.jetBlack,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(Icons.videocam_outlined, size: 64, color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: "Give your live video a title",
                  filled: true,
                  fillColor: AppColors.groupCardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _privacyOption("public", "Public")),
                  const SizedBox(width: 10),
                  Expanded(child: _privacyOption("friends", "Friends")),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: TextButton(
                    onPressed: _comingSoon,
                    child: Text(
                      "Go Live",
                      style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacyOption(String value, String label) {
    final selected = _privacy == value;
    return GestureDetector(
      onTap: () => setState(() => _privacy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.tabSelectedFill : Colors.transparent,
          border: Border.all(color: selected ? AppColors.tabSelectedBorder : AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.jetBlack)),
        ),
      ),
    );
  }
}
