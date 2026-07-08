import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';

/// Matches the K54 Figma file's Members screen exactly (node 55:1914,
/// measured + rendered via the Figma REST API, 2026-07-08). Still
/// hardcoded mock data - no real Members API confirmed yet, per the
/// UI-first strategy. member1/2/3.png (the original mock image paths)
/// don't exist on disk, so avatars fall back to initials rather than
/// attempting to load a nonexistent asset.
class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  int selectedTab = 0;

  final List<String> tabs = ["All Members", "My Connections", "Following", "Followers"];

  final List<Map<String, String>> members = [
    {"name": "EVELYN", "joined": "Joined Feb 2026", "status": "Active", "followers": "39"},
    {"name": "DANIEL", "joined": "Joined Jan 2026", "status": "Active", "followers": "102"},
    {"name": "MICHAEL", "joined": "Joined Mar 2026", "status": "Online", "followers": "85"},
  ];

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature is coming soon")),
    );
  }

  Widget _iconChip({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.iconButtonBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppColors.jetBlack),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _iconChip(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.groupCardBackground,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 14, color: AppColors.gold),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              onChanged: (_) => _comingSoon("Search members"),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: "Search members",
                                hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.gold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _iconChip(
                    icon: Icons.filter_list,
                    onTap: () => _comingSoon("Filters"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(tabs.length, (index) {
                  final isSelected = selectedTab == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: GestureDetector(
                      onTap: () => setState(() => selectedTab = index),
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected ? AppColors.green : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          tabs[index],
                          style: GoogleFonts.poppins(fontSize: 10, color: AppColors.jetBlack),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    "97 Members",
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.jetBlack,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _comingSoon("Sort"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.groupCardAccent, width: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Recently Active",
                            style: GoogleFonts.lato(fontSize: 10, color: AppColors.groupMutedText),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 12, color: AppColors.groupMutedText),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _comingSoon("Grid view"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.groupCardAccent, width: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.grid_view, size: 12, color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => _memberCard(members[index]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const K54BottomNavigation(currentIndex: 2),
    );
  }

  Widget _memberCard(Map<String, String> member) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.groupCardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.groupCardAccent),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        member["name"]!.isNotEmpty ? member["name"]![0] : "?",
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.onlineIndicator,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  member["name"]!,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.jetBlack,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF588D58)),
                    children: [
                      TextSpan(text: "${member["joined"]}  "),
                      TextSpan(
                        text: member["status"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.lato(fontSize: 12, color: AppColors.groupMutedText),
                    children: [
                      TextSpan(text: "${member["followers"]} "),
                      const TextSpan(
                        text: "Followers",
                        style: TextStyle(color: Color(0xFF588D58)),
                      ),
                    ],
                  ),
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
                _memberAction(Icons.thumb_down_outlined, () => _comingSoon("Block")),
                _memberAction(Icons.person_add_alt_1_outlined, () => _comingSoon("Connect")),
                _memberAction(Icons.chat_bubble_outline, () => _comingSoon("Message")),
                _memberAction(Icons.call_outlined, () => _comingSoon("Voice call")),
                _memberAction(Icons.videocam_outlined, () => _comingSoon("Video call")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberAction(IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
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
