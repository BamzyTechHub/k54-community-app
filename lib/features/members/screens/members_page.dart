import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/nav.dart';
import 'package:k54_mobile/core/utils/responsive.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';
import 'package:k54_mobile/core/widgets/member_card.dart';
import 'package:k54_mobile/features/friends/models/friendship_model.dart';
import 'package:k54_mobile/features/friends/repositories/friends_repository.dart';
import 'package:k54_mobile/features/members/controllers/members_controller.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
import 'package:k54_mobile/features/messaging/screens/chat_page.dart';
import 'package:k54_mobile/features/profile/screens/profile_page.dart';

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
  bool _gridView = true;

  final MembersController _membersController = MembersController();
  List<Friendship> _connections = [];
  bool _loadingConnections = true;
  String? _connectionsError;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: userId)));
  }

  Future<void> _openMessage(String userId) async {
    try {
      final thread = await MessagingRepository.instance.findOrCreateThreadWith(otherUserId: userId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatPage(threadId: thread.id, thread: thread)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't open chat: $e")));
    }
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
                              onChanged: _membersController.search,
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
                  _iconChip(icon: Icons.filter_list, onTap: () => _comingSoon("Filters")),
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
    return GestureDetector(
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
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_membersController.error != null && _membersController.members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load members.\n${_membersController.error}", textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: () => _membersController.load(), child: const Text("Retry")),
          ],
        ),
      );
    }
    if (_membersController.members.isEmpty) {
      return const Center(child: Text("No members found"));
    }

    final members = _membersController.members;
    final itemCount = members.length + (_membersController.loadingMore ? 1 : 0);

    Widget loadingTile() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)),
        );

    Widget tile(int index) {
      final member = members[index];
      return _memberCard(id: member.id, name: member.name, avatarUrl: member.avatarUrl);
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
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (_connectionsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load connections.\n$_connectionsError", textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadConnections, child: const Text("Retry")),
          ],
        ),
      );
    }
    if (_connections.isEmpty) {
      return const Center(child: Text("No connections yet"));
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _loadConnections,
      child: ListView.separated(
        itemCount: _connections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final f = _connections[index];
          return _memberCard(id: f.otherUserId, name: f.otherUserName, avatarUrl: f.otherUserAvatar);
        },
      ),
    );
  }

  Widget _memberCard({required String id, required String name, String? avatarUrl}) {
    return MemberCard(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      onTap: () => _openProfile(id),
      onBlock: () => _comingSoon("Block"),
      onConnect: () => _comingSoon("Connect"),
      onMessage: () => _openMessage(id),
      onCall: () => _comingSoon("Voice call"),
      onVideoCall: () => _comingSoon("Video call"),
    );
  }
}
