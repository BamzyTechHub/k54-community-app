import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';

/// Single source of truth for the Groups screen, reused from both places
/// it's reachable in the app: the main bottom nav (as its own pushed
/// destination, [embedded] = false, matching Figma node 87:76 "GROUPS")
/// and the Messages/Friends/Groups tab bar (as one tab's body,
/// [embedded] = true, matching Figma node 50:1523 "Groups") - these are
/// two genuinely different Figma layouts (a rich directory vs. a compact
/// list), not just a chrome difference, both measured directly via the
/// Figma REST API on 2026-07-08.
///
/// Still using hardcoded mock content - no real Groups API has been
/// confirmed yet (this is a UI-first pass per the new development
/// strategy), so joining/creating/filtering are not wired to anything
/// real. TODOs mark exactly what needs a confirmed endpoint before this
/// becomes functional.
class GroupsPage extends StatefulWidget {
  final bool embedded;

  const GroupsPage({super.key, this.embedded = false});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  int selectedTab = 0;

  final List<String> tabs = ["All Groups", "My Groups", "Create a Group"];

  final List<Map<String, dynamic>> groups = [
    {
      "name": "Feast for Families, Inc",
      "type": "Public",
      "active": "Active 3 days ago",
      "isOwner": true,
      "cover": "assets/images/group_cover1.png",
      "logo": "assets/images/group_logo1.png",
    },
    {
      "name": "Fit23 Health & Wellness",
      "type": "Public",
      "active": "Active 6 days ago",
      "isOwner": false,
      "cover": "assets/images/group_cover2.png",
      "logo": "assets/images/group_logo2.png",
    },
    {
      "name": "Business Growth Network",
      "type": "Private",
      "active": "Active today",
      "isOwner": false,
      "cover": "assets/images/group_cover3.png",
      "logo": "assets/images/group_logo3.png",
    },
  ];

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature is coming soon")),
    );
  }

  Widget _iconChip({required IconData icon, required VoidCallback onTap, double size = 16}) {
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
        child: Icon(icon, size: size, color: AppColors.jetBlack),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: _buildEmbeddedList(context)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _buildFullDirectory(context)),
      bottomNavigationBar: const K54BottomNavigation(currentIndex: 3),
    );
  }

  /// Compact list matching Figma node 50:1523 - reached from the
  /// Messages/Friends/Groups tab bar.
  Widget _buildEmbeddedList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              _iconChip(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
              const SizedBox(width: 10),
              Text(
                "Groups",
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.jetBlack,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _comingSoon(context, "Search"),
                child: const Icon(Icons.search, size: 18, color: AppColors.jetBlack),
              ),
              const SizedBox(width: 10),
              _iconChip(
                icon: Icons.videocam_outlined,
                onTap: () => _comingSoon(context, "Group video call"),
              ),
              const SizedBox(width: 8),
              _iconChip(
                icon: Icons.call_outlined,
                onTap: () => _comingSoon(context, "Group call"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: groups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final group = groups[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.friendRowBackground,
                    border: Border.all(color: AppColors.friendRowBorder),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey.shade200,
                        child: Text(group["name"].isNotEmpty ? group["name"][0] : "?"),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          group["name"],
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.jetBlack,
                          ),
                        ),
                      ),
                      const Icon(Icons.groups_outlined, size: 20, color: AppColors.jetBlack),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Rich directory matching Figma node 87:76 - reached from the main
  /// bottom nav.
  Widget _buildFullDirectory(BuildContext context) {
    return Padding(
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
                          onChanged: (_) => _comingSoon(context, "Search groups"),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: "Search groups",
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
                icon: Icons.filter_alt_outlined,
                onTap: () => _comingSoon(context, "Filters"),
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
                "${groups.length} Groups",
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.jetBlack,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _comingSoon(context, "Sort"),
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
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.groupMutedText,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 12, color: AppColors.groupMutedText),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _comingSoon(context, "Grid view"),
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
              itemCount: groups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _groupCard(context, groups[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupCard(BuildContext context, Map<String, dynamic> group) {
    final isOwner = group["isOwner"] == true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.groupCardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.groupCardAccent),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                group["cover"],
                height: 99,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(height: 99, color: const Color(0xFF6A6A6A)),
              ),
              Positioned(
                left: 8,
                bottom: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: Text(group["name"].isNotEmpty ? group["name"][0] : "?"),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 36, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group["name"],
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.jetBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      group["type"],
                      style: GoogleFonts.lato(fontSize: 12, color: AppColors.groupCardAccent),
                    ),
                    _dot(),
                    Text(
                      "Group",
                      style: GoogleFonts.lato(fontSize: 12, color: AppColors.groupCardAccent),
                    ),
                    _dot(),
                    Expanded(
                      child: Text(
                        group["active"],
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(fontSize: 12, color: AppColors.groupCardAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    _memberStack(),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _comingSoon(context, isOwner ? "Managing this group" : "Joining groups"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOwner ? AppColors.groupCardAccent : Colors.transparent,
                          border: Border.all(color: AppColors.groupCardAccent, width: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOwner ? Icons.check : Icons.add,
                              size: 12,
                              color: isOwner ? AppColors.jetBlack : AppColors.groupMutedText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOwner ? "Organizer" : "Join Group",
                              style: GoogleFonts.lato(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isOwner ? AppColors.jetBlack : AppColors.groupMutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 7),
      width: 4,
      height: 4,
      decoration: const BoxDecoration(color: AppColors.groupMutedText, shape: BoxShape.circle),
    );
  }

  Widget _memberStack() {
    return SizedBox(
      width: 77,
      height: 24,
      child: Stack(
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: i * 18.0,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: [Colors.blue, Colors.orange, Colors.purple][i],
                ),
              ),
            ),
          Positioned(
            left: 54,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.friendRowBorder,
                child: const Icon(Icons.more_horiz, size: 12, color: Color(0xFF7E7D7D)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
