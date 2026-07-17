import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/k54_route.dart';
import 'package:k54_mobile/core/utils/open_profile.dart';
import 'package:k54_mobile/core/utils/responsive.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/k54_search_field.dart';
import 'package:k54_mobile/core/widgets/member_card.dart';
import 'package:k54_mobile/core/widgets/skeleton_loaders.dart';
import 'package:k54_mobile/core/widgets/state_views.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/core/widgets/underline_tab_row.dart';
import 'package:k54_mobile/features/friends/models/friendship_model.dart';
import 'package:k54_mobile/features/friends/repositories/friends_repository.dart';
import 'package:k54_mobile/features/members/controllers/members_controller.dart';
import 'package:k54_mobile/features/members/widgets/members_filter_popover.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
import 'package:k54_mobile/features/messaging/screens/chat_page.dart';

/// Matches the K54 Figma file's Members screen exactly (node 55:1914).
///
/// "All Members" is wired to the confirmed `GET /buddyboss/v1/members`
/// (the same endpoint messaging's search already proves works). "My
/// Connections" reuses FriendsRepository rather than a duplicate local
/// model, since BuddyBoss connections and this app's Friends feature are
/// the same underlying relationship - no confirmed REST equivalent
/// exists for the website's own "Following"/"Followers" admin-ajax
/// scopes, so those two tabs are stubbed rather than guessed at.
class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  int selectedTab = 0;
  final tabs = const ["All Members", "My Connections", "Following", "Followers"];

  /// Matches BP-REST's confirmed `type` sort values for this endpoint.
  static const _sortOptions = {
    "active": "Recently Active",
    "newest": "Newest",
    "alphabetical": "Alphabetical",
    "popular": "Most Popular",
  };
  // Figma's default state (node 55:1914) shows the single-column list, not
  // the 2-column grid - confirmed via the rendered card widths taking the
  // full row.
  bool _gridView = false;

  final MembersController _membersController = MembersController();
  List<Friendship> _connections = [];
  bool _loadingConnections = true;
  String? _connectionsError;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LayerLink _filterLayerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _membersController.addListener(() => setState(() {}));
    _membersController.load();
    _loadConnections();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (selectedTab != 0) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _membersController.loadMore();
    }
  }

  Future<void> _loadConnections() async {
    setState(() {
      _loadingConnections = true;
      _connectionsError = null;
    });
    try {
      _connections = await FriendsRepository.instance.getFriends();
    } catch (e) {
      _connectionsError = e.toString();
    } finally {
      if (mounted) setState(() => _loadingConnections = false);
    }
  }

  @override
  void dispose() {
    _membersController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature is coming soon")),
    );
  }

  void _openProfile(String userId) {
    openProfile(context, userId);
  }

  void _openFilterPopover() {
    showMembersFilterPopover(
      context: context,
      layerLink: _filterLayerLink,
      currentSort: _membersController.sortType,
      onSortSelected: (key) => _membersController.sortBy(key),
      onSearchFilterTapped: (label) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Filtering by $label isn't available yet")),
      ),
    );
  }

  Future<void> _openMessage(String userId) async {
    try {
      final thread = await MessagingRepository.instance.findOrCreateThreadWith(otherUserId: userId);
      if (!mounted) return;
      Navigator.push(
        context,
        k54Route(ChatPage(threadId: thread.id, thread: thread)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't open chat: $e")));
    }
  }

  // Figma's Members header (node 55:1914) shows the back arrow and filter
  // icon plain, with no circular chip background - unlike Messages'
  // header, which does use one. Kept screen-accurate rather than reused
  // wholesale from Messages.
  Widget _plainIcon({required IconData icon, required VoidCallback onTap}) {
    return TapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 22, color: AppColors.jetBlack),
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
                  // No back arrow - Members is a main bottom-nav
                  // destination (reached via pushReplacement, same as AI
                  // Assistant/Home/Groups/Courses), not a pushed screen,
                  // and the real header doesn't show one. Confirmed
                  // 2026-07-18 after the user pointed out the header had
                  // an extra element beside the search bar that Figma
                  // doesn't have.
                  Expanded(
                    child: K54SearchField(
                      controller: _searchController,
                      onChanged: _membersController.search,
                      hintText: "Search members",
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
                onChanged: (index) => setState(() => selectedTab = index),
              ),
              const SizedBox(height: 12),
              if (selectedTab == 0) ...[
                _buildMembersToolbar(),
                const SizedBox(height: 12),
              ],
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const K54BottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildBody() {
    switch (selectedTab) {
      case 0:
        return _buildAllMembers();
      case 1:
        return _buildConnections();
      default:
        return Center(
          child: Text(
            "${tabs[selectedTab]} isn't available yet",
            style: GoogleFonts.lato(color: Colors.grey.shade600),
          ),
        );
    }
  }

  /// Matches Figma's row above the member list: total count, the
  /// "Recently Active" sort dropdown (wired to BP-REST's confirmed
  /// `type` param), and a grid/list view toggle (cosmetic only - both
  /// modes render the same real data, no backend involved).
  Widget _buildMembersToolbar() {
    final total = _membersController.totalCount;
    return Row(
      children: [
        Text(
          total != null ? "$total Members" : "Members",
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
              value: _membersController.sortType,
              icon: const Icon(Icons.keyboard_arrow_down, size: 15),
              isDense: true,
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.jetBlack),
              items: _sortOptions.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) {
                if (value != null) _membersController.sortBy(value);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 28,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.groupCardAccent),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _viewToggleIcon(Icons.grid_view, _gridView, () => setState(() => _gridView = true)),
              _viewToggleIcon(Icons.view_list, !_gridView, () => setState(() => _gridView = false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _viewToggleIcon(IconData icon, bool selected, VoidCallback onTap) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: 28,
        alignment: Alignment.center,
        child: Icon(icon, size: 15, color: selected ? AppColors.green : Colors.grey),
      ),
    );
  }

  Widget _buildAllMembers() {
    if (_membersController.loading && _membersController.members.isEmpty) {
      return _gridView
          ? SkeletonCardGrid(crossAxisCount: Responsive.gridColumns(context))
          : const SkeletonRowList();
    }
    if (_membersController.error != null && _membersController.members.isEmpty) {
      return K54ErrorState(
        message: "Couldn't load members.\n${_membersController.error}",
        onRetry: () => _membersController.load(),
      );
    }
    if (_membersController.members.isEmpty) {
      return const K54EmptyState(icon: Icons.people_outline, message: "No members found");
    }

    final members = _membersController.members;
    final itemCount = members.length + (_membersController.loadingMore ? 1 : 0);

    Widget loadingTile() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)),
        );

    Widget tile(int index) {
      final member = members[index];
      return FadeSlideIn(
        key: ValueKey(member.id),
        delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
        child: _memberCard(id: member.id, name: member.name, avatarUrl: member.avatarUrl),
      );
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () => _membersController.load(),
      child: _gridView
          ? GridView.builder(
              controller: _scrollController,
              itemCount: itemCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Responsive.gridColumns(context),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) =>
                  index >= members.length ? loadingTile() : tile(index),
            )
          : ListView.separated(
              controller: _scrollController,
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  index >= members.length ? loadingTile() : tile(index),
            ),
    );
  }

  Widget _buildConnections() {
    if (_loadingConnections) {
      return const SkeletonRowList();
    }
    if (_connectionsError != null) {
      return K54ErrorState(
        message: "Couldn't load connections.\n$_connectionsError",
        onRetry: _loadConnections,
      );
    }
    if (_connections.isEmpty) {
      return const K54EmptyState(icon: Icons.people_outline, message: "No connections yet");
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _loadConnections,
      child: ListView.separated(
        itemCount: _connections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final f = _connections[index];
          return FadeSlideIn(
            key: ValueKey(f.otherUserId),
            delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
            child: _memberCard(id: f.otherUserId, name: f.otherUserName, avatarUrl: f.otherUserAvatar),
          );
        },
      ),
    );
  }

  Future<void> _blockMember(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: K54Dialog.shape,
        title: const Text("Block member"),
        content: Text("Block $name? They won't be able to message you."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Block", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await MessagingRepository.instance.blockUser(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name has been blocked")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't block $name: $e")));
    }
  }

  Widget _memberCard({required String id, required String name, String? avatarUrl}) {
    return MemberCard(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      onTap: () => _openProfile(id),
      onBlock: () => _blockMember(id, name),
      onConnect: () => _comingSoon("Connect"),
      onMessage: () => _openMessage(id),
      onCall: () => _comingSoon("Voice call"),
      onVideoCall: () => _comingSoon("Video call"),
    );
  }
}
