import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/responsive.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';
import 'package:k54_mobile/core/widgets/contact_row.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/core/widgets/filter_popover.dart';
import 'package:k54_mobile/core/widgets/k54_search_field.dart';
import 'package:k54_mobile/core/widgets/pressable_pill.dart';
import 'package:k54_mobile/core/widgets/skeleton_loaders.dart';
import 'package:k54_mobile/core/widgets/state_views.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/core/widgets/underline_tab_row.dart';
import 'package:k54_mobile/core/widgets/user_avatar.dart';
import 'package:k54_mobile/features/groups/controllers/groups_controller.dart';
import 'package:k54_mobile/features/groups/models/group_model.dart';
import 'package:k54_mobile/features/groups/repositories/groups_repository.dart';
import 'package:k54_mobile/features/groups/widgets/create_group_dialog.dart';

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

  // BP-REST's confirmed `orderby` values for this endpoint - shared by
  // the toolbar's inline dropdown and the header filter icon's popover,
  // both of which drive the same real _allGroupsController.sortBy().
  static const _sortOptions = {
    "last_activity": "Recently Active",
    "date_created": "Newest",
    "name": "Alphabetical",
    "total_member_count": "Most Members",
  };

  final GroupsController _allGroupsController = GroupsController();
  final MyGroupsController _myGroupsController = MyGroupsController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LayerLink _filterLayerLink = LayerLink();

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

  void _openFilterPopover() {
    showFilterPopover(
      context: context,
      layerLink: _filterLayerLink,
      sections: [
        FilterSection(
          label: "Groups view filter",
          options: _sortOptions.entries
              .map((e) => FilterOption(
                    label: e.value,
                    selected: _allGroupsController.orderby == e.key,
                    onTap: () => _allGroupsController.sortBy(e.key),
                  ))
              .toList(),
        ),
      ],
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
    final details = await showCreateGroupDialog(context);
    if (details == null || !mounted) return;

    try {
      await GroupsRepository.instance.createGroup(
        name: details.name,
        description: details.description,
        status: details.privacy,
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

  // Both Groups frames in Figma (50:1523 embedded, 87:76 full directory)
  // show plain icons with no circular chip background - unlike Messages'
  // header, which does use one.
  Widget _plainIcon({required IconData icon, required VoidCallback onTap, double size = 22}) {
    return TapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
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

  /// Compact list for Figma node 50:1523 - reached from the
  /// Messages/Friends/Groups tab bar. Always shows "All Groups".
  ///
  /// Header icons: node 50:1523 itself couldn't be pulled (Figma API
  /// 429-rate-limited mid-session, 2026-07-16) so this exact row isn't
  /// directly confirmed. The videocam/call/more_vert icons removed here
  /// were fake "_comingSoon" stubs regardless of the exact real layout,
  /// and the other two frames in this same Messages/Friends/Groups
  /// sub-tab family (Messages node 43:104, Friends node 50:1005) were
  /// both directly confirmed to show only a search icon in this
  /// position - matching that pattern here is a reasonable inference,
  /// not a guess, but flagged as pending final confirmation once the
  /// rate limit clears.
  Widget _buildEmbeddedList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              _plainIcon(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
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
              // No back arrow - Groups' full directory is a main
              // bottom-nav destination (reached via pushReplacement, same
              // as AI Assistant/Members/Home/Courses), not a pushed
              // screen.
              Expanded(
                child: K54SearchField(
                  controller: _searchController,
                  onChanged: _allGroupsController.search,
                  hintText: "Search groups",
                  height: 24,
                  iconSize: 14,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              CompositedTransformTarget(
                link: _filterLayerLink,
                child: _plainIcon(icon: Icons.filter_alt_outlined, onTap: _openFilterPopover),
              ),
            ],
          ),
          const SizedBox(height: 16),
          UnderlineTabRow(
            tabs: tabs,
            selectedIndex: selectedTab,
            onChanged: (index) {
              // "Create a Group" is a dialog trigger, not a real content
              // tab - it used to also become the "selected" tab, which
              // left the underline stuck there after the dialog closed
              // (with the list underneath silently still showing "All
              // Groups", since nothing renders a dedicated tab-2 body).
              // Found via a code trace, not runtime testing.
              if (index == 2) {
                _createGroup();
                return;
              }
              setState(() => selectedTab = index);
            },
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
              items: _sortOptions.entries
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
      return const SkeletonRowList();
    }
    if (error != null && groups.isEmpty) {
      return K54ErrorState(
        message: "Couldn't load groups.\n$error",
        onRetry: () => selectedTab == 1 ? _myGroupsController.load() : _allGroupsController.load(),
      );
    }
    if (groups.isEmpty) {
      return K54EmptyState(
        icon: Icons.groups_outlined,
        message: selectedTab == 1 ? "You haven't joined any groups yet" : "No groups found",
      );
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
      child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Responsive.isTablet(context) ? 640 : double.infinity),
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
      ),
      ),
    );
  }

  Widget _embeddedGroupTile(Group group) {
    return ContactRow(
      avatarUrl: group.avatarUrl,
      title: group.name,
      trailing: const Icon(Icons.groups_outlined, size: 20, color: AppColors.jetBlack),
    );
  }

  Widget _groupCard(BuildContext context, Group group) {
    final isMember = _myGroupIds.contains(group.id);

    return Container(
      decoration: BoxDecoration(
        // Exact colors from the GROUPS Figma frame (node 87:76, "member
        // comp"), pulled via the REST API 2026-07-16 - was the tan/
        // sage-green pair (groupCardBackground/groupCardAccent) before
        // this measurement existed.
        color: const Color(0xFFFCF8ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.green),
      ),
      // Explicit ClipRRect (inset 1px inside the border stroke) instead of
      // relying on Container's own clipBehavior - that didn't reliably
      // round the cover image's top corners in practice (same bug found
      // and fixed on MemberCard's bottom action-row strip).
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
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
                  child: UserAvatar(imageUrl: group.avatarUrl, name: group.name),
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
                // Right-aligned pill, matching Figma's "Organizer"/"Join
                // Group" button placement (node 87:76) - the member-avatar
                // stack shown alongside it in Figma is skipped since no
                // confirmed endpoint returns per-group member avatars.
                // Shared PressablePill rather than a hand-rolled button, so
                // it picks up the app-wide active/inactive button colors.
                Align(
                  alignment: Alignment.centerRight,
                  child: PressablePill(
                    label: isMember ? "Joined" : "Join Group",
                    icon: isMember ? Icons.check : Icons.add,
                    filled: isMember,
                    height: 34,
                    onTap: () => _toggleMembership(group),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
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
