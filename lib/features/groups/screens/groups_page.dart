import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/nav.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/features/groups/controllers/groups_controller.dart';
import 'package:k54_mobile/features/groups/models/group_model.dart';
import 'package:k54_mobile/features/groups/repositories/groups_repository.dart';

/// Single source of truth for the Groups screen, reused from three places
/// it's reachable in the app: the main bottom nav (as its own pushed
/// destination, [embedded] = false, matching Figma node 87:76 "GROUPS"),
/// the Messages/Friends/Groups tab bar (as one tab's body, [embedded] =
/// true, matching Figma node 50:1523 "Groups"), and the Profile page's
/// own "Groups" tab (also [embedded] = true).
///
/// Wired to the confirmed `/buddyboss/v1/groups` REST surface (see
/// group_model.dart's doc comment - sourced from BuddyPress's open-source
/// BP-REST plugin, same evidence-based approach as Friends). List,
/// create, join, and leave are all real; "Organizer" vs. plain "Join"
/// distinction from the earlier mock UI is dropped since no confirmed
/// field identifies the current user's role within a group - only
/// membership (join/leave) is shown, which is fully confirmed.
class GroupsPage extends StatefulWidget {
  final bool embedded;

  const GroupsPage({super.key, this.embedded = false});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  int selectedTab = 0;
  final tabs = const ["All Groups", "My Groups", "Create a Group"];

  final GroupsController _allGroupsController = GroupsController();
  final MyGroupsController _myGroupsController = MyGroupsController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Set<String> _myGroupIds = {};

  @override
  void initState() {
    super.initState();
    _allGroupsController.addListener(() => setState(() {}));
    _myGroupsController.addListener(_onMyGroupsChanged);
    _allGroupsController.load();
    _myGroupsController.load();
    _scrollController.addListener(_onScroll);
  }

  void _onMyGroupsChanged() {
    setState(() {
      _myGroupIds = _myGroupsController.groups.map((g) => g.id).toSet();
    });
  }

  void _onScroll() {
    if (selectedTab != 0) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _allGroupsController.loadMore();
    }
  }

  @override
  void dispose() {
    _allGroupsController.dispose();
    _myGroupsController.removeListener(_onMyGroupsChanged);
    _myGroupsController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature is coming soon")),
    );
  }

  Future<void> _toggleMembership(Group group) async {
    final isMember = _myGroupIds.contains(group.id);
    // Optimistic - flips the button instantly instead of waiting on the
    // round-trip + a full My Groups refetch, then reconciles for real.
    setState(() {
      if (isMember) {
        _myGroupIds.remove(group.id);
      } else {
        _myGroupIds.add(group.id);
      }
    });
    try {
      if (isMember) {
        await GroupsRepository.instance.leaveGroup(group.id);
      } else {
        await GroupsRepository.instance.joinGroup(group.id);
      }
      await _myGroupsController.load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (isMember) {
          _myGroupIds.add(group.id);
        } else {
          _myGroupIds.remove(group.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't update membership: $e")),
      );
    }
  }

  Future<void> _createGroup() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String status = "public";

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text("Create a Group"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Group Name")),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: "Privacy"),
                items: const [
                  DropdownMenuItem(value: "public", child: Text("Public")),
                  DropdownMenuItem(value: "private", child: Text("Private")),
                  DropdownMenuItem(value: "hidden", child: Text("Hidden")),
                ],
                onChanged: (value) => setDialogState(() => status = value ?? "public"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Create")),
          ],
        ),
      ),
    );

    if (confirmed != true || nameController.text.trim().isEmpty || !mounted) return;

    try {
      await GroupsRepository.instance.createGroup(
        name: nameController.text.trim(),
        description: descController.text.trim(),
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Group created")));
      setState(() => selectedTab = 0);
      _allGroupsController.load();
      _myGroupsController.load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't create group: $e")));
    }
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
  /// Messages/Friends/Groups tab bar. Always shows "All Groups".
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
                style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _comingSoon(context, "Search"),
                child: const Icon(Icons.search, size: 18, color: AppColors.jetBlack),
              ),
              const SizedBox(width: 10),
              _iconChip(icon: Icons.videocam_outlined, onTap: () => _comingSoon(context, "Group video call")),
              const SizedBox(width: 8),
              _iconChip(icon: Icons.call_outlined, onTap: () => _comingSoon(context, "Group call")),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _comingSoon(context, "More options"),
                child: const Icon(Icons.more_vert, size: 18, color: AppColors.jetBlack),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildGroupsList(embedded: true)),
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
              _iconChip(icon: Icons.arrow_back, onTap: () => goHome(context)),
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
                          controller: _searchController,
                          onChanged: _allGroupsController.search,
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
              _iconChip(icon: Icons.filter_alt_outlined, onTap: () => _comingSoon(context, "Filters")),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(tabs.length, (index) {
              final isSelected = selectedTab == index;
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () {
                    setState(() => selectedTab = index);
                    if (index == 2) _createGroup();
                  },
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
          if (selectedTab == 0) ...[
            _buildGroupsToolbar(),
            const SizedBox(height: 12),
          ],
          Expanded(child: _buildGroupsList(embedded: false)),
        ],
      ),
    );
  }

  /// Matches Figma's row above the group list: total count and the
  /// "Recently Active" sort dropdown, wired to BP-REST's confirmed
  /// `orderby` param. Figma also shows a grid/list view toggle here, but
  /// group cards (cover image + join button) aren't designed for a
  /// 2-column grid the way member cards are, so that part is skipped
  /// rather than forcing a broken-looking layout.
  Widget _buildGroupsToolbar() {
    const sortOptions = {
      "last_activity": "Recently Active",
      "date_created": "Newest",
      "name": "Alphabetical",
      "total_member_count": "Most Members",
    };
    final total = _allGroupsController.totalCount;
    return Row(
      children: [
        Text(
          total != null ? "$total Groups" : "Groups",
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.jetBlack),
        ),
        const Spacer(),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.groupCardAccent),
            borderRadius: BorderRadius.circular(7),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _allGroupsController.orderby,
              icon: const Icon(Icons.keyboard_arrow_down, size: 15),
              isDense: true,
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.jetBlack),
              items: sortOptions.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) {
                if (value != null) _allGroupsController.sortBy(value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsList({required bool embedded}) {
    final controller = selectedTab == 1 ? null : _allGroupsController;
    final loading = selectedTab == 1 ? _myGroupsController.loading : _allGroupsController.loading;
    final error = selectedTab == 1 ? _myGroupsController.error : _allGroupsController.error;
    final groups = selectedTab == 1 ? _myGroupsController.groups : _allGroupsController.groups;

    if (loading && groups.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (error != null && groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load groups.\n$error", textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => selectedTab == 1 ? _myGroupsController.load() : _allGroupsController.load(),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }
    if (groups.isEmpty) {
      return Center(child: Text(selectedTab == 1 ? "You haven't joined any groups yet" : "No groups found"));
    }

    if (embedded) {
      return ListView.separated(
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, index) => FadeSlideIn(
          key: ValueKey(groups[index].id),
          delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
          child: _embeddedGroupTile(groups[index]),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () async => controller?.load() ?? _myGroupsController.load(),
      child: ListView.separated(
        controller: selectedTab == 0 ? _scrollController : null,
        itemCount: groups.length + (_allGroupsController.loadingMore && selectedTab == 0 ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= groups.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)),
            );
          }
          return FadeSlideIn(
            key: ValueKey(groups[index].id),
            delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
            child: _groupCard(context, groups[index]),
          );
        },
      ),
    );
  }

  Widget _embeddedGroupTile(Group group) {
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
            backgroundImage: group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                ? NetworkImage(group.avatarUrl!)
                : null,
            child: group.avatarUrl == null || group.avatarUrl!.isEmpty
                ? Text(group.name.isNotEmpty ? group.name[0] : "?")
                : null,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              group.name,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.jetBlack),
            ),
          ),
          const Icon(Icons.groups_outlined, size: 20, color: AppColors.jetBlack),
        ],
      ),
    );
  }

  Widget _groupCard(BuildContext context, Group group) {
    final isMember = _myGroupIds.contains(group.id);

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
              group.coverUrl != null && group.coverUrl!.isNotEmpty
                  ? Image.network(
                      group.coverUrl!,
                      height: 99,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(height: 99, color: const Color(0xFF6A6A6A)),
                    )
                  : Container(height: 99, color: const Color(0xFF6A6A6A)),
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
                    backgroundImage: group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                        ? NetworkImage(group.avatarUrl!)
                        : null,
                    child: group.avatarUrl == null || group.avatarUrl!.isEmpty
                        ? Text(group.name.isNotEmpty ? group.name[0] : "?")
                        : null,
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
                  group.name,
                  style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.jetBlack),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(group.status, style: GoogleFonts.lato(fontSize: 12, color: AppColors.groupCardAccent)),
                    _dot(),
                    Text("Group", style: GoogleFonts.lato(fontSize: 12, color: AppColors.groupCardAccent)),
                    _dot(),
                    Expanded(
                      child: Text(
                        "${group.totalMemberCount} members",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(fontSize: 12, color: AppColors.groupCardAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleMembership(group),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isMember ? AppColors.groupCardAccent : Colors.transparent,
                          border: Border.all(color: AppColors.groupCardAccent, width: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isMember ? Icons.check : Icons.add,
                              size: 12,
                              color: isMember ? AppColors.jetBlack : AppColors.groupMutedText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isMember ? "Joined" : "Join Group",
                              style: GoogleFonts.lato(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isMember ? AppColors.jetBlack : AppColors.groupMutedText,
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
}
