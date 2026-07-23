import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/k54_route.dart';
import 'package:k54_mobile/core/utils/open_profile.dart';
import 'package:k54_mobile/core/utils/responsive.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';
import 'package:k54_mobile/core/widgets/contact_row.dart';
import 'package:k54_mobile/core/widgets/fade_slide_in.dart';
import 'package:k54_mobile/core/widgets/filter_popover.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/k54_search_field.dart';
import 'package:k54_mobile/core/widgets/member_card.dart';
import 'package:k54_mobile/core/widgets/pressable_pill.dart';
import 'package:k54_mobile/core/widgets/skeleton_loaders.dart';
import 'package:k54_mobile/core/widgets/state_views.dart';
import 'package:k54_mobile/core/widgets/tap_scale.dart';
import 'package:k54_mobile/core/widgets/underline_tab_row.dart';
import 'package:k54_mobile/features/friends/models/friendship_model.dart';
import 'package:k54_mobile/features/friends/repositories/friends_repository.dart';
import 'package:k54_mobile/features/members/controllers/members_controller.dart';
import 'package:k54_mobile/features/members/models/member_model.dart';
import 'package:k54_mobile/features/members/repositories/members_repository.dart';
import 'package:k54_mobile/features/members/widgets/members_filter_popover.dart';
import 'package:k54_mobile/features/messaging/calling/call_screen.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
import 'package:k54_mobile/features/messaging/screens/chat_page.dart';

/// Matches the K54 Figma file's Members screen exactly (node 55:1914).
///
/// "All Members" is wired to the confirmed `GET /buddyboss/v1/members`
/// (the same endpoint messaging's search already proves works). "My
/// Connections" reuses FriendsRepository rather than a duplicate local
/// model, since BuddyBoss connections and this app's Friends feature are
/// the same underlying relationship. "Following"/"Followers" are real now
/// too (2026-07-21) - `scope=following`/`scope=followers` are confirmed
/// real enum values on this same `/buddyboss/v1/members` endpoint (its
/// own arg schema), and `POST members/action/{id}` with
/// `{"action":"follow"|"unfollow"}` is the real toggle - both confirmed
/// live (test-and-revert against this app's own account).
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

  String? _myUserId;
  List<Member>? _following;
  List<Member>? _followers;
  bool _loadingFollowTab = false;
  Object? _followTabError;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LayerLink _filterLayerLink = LayerLink();
  final LayerLink _sortLayerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _membersController.addListener(() => setState(() {}));
    _membersController.load();
    _loadConnections();
    _scrollController.addListener(_onScroll);
    _loadMyUserId();
  }

  Future<void> _loadMyUserId() async {
    try {
      final id = (await AuthService().getCurrentUser()).data["id"]?.toString();
      if (mounted) setState(() => _myUserId = id);
    } catch (_) {
      // Non-fatal - cards just won't know to hide the action row for the
      // current user's own card if this fails.
    }
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

  Future<void> _loadFollowTab(String scope) async {
    setState(() {
      _loadingFollowTab = true;
      _followTabError = null;
    });
    try {
      _myUserId ??= (await AuthService().getCurrentUser()).data["id"]?.toString();
      final result = await MembersRepository.instance.getMembers(scope: scope, userId: _myUserId, perPage: 50);
      if (!mounted) return;
      setState(() {
        if (scope == "following") {
          _following = result.members;
        } else {
          _followers = result.members;
        }
        _loadingFollowTab = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _followTabError = e;
        _loadingFollowTab = false;
      });
    }
  }

  Future<void> _toggleFollow(Member member, bool follow) async {
    // Optimistic - flips the pill instantly, reconciles for real after.
    setState(() {
      if (_following != null) {
        _following = _following!.map((m) => m.id == member.id ? _withFollowing(m, follow) : m).toList();
      }
      if (_followers != null) {
        _followers = _followers!.map((m) => m.id == member.id ? _withFollowing(m, follow) : m).toList();
      }
    });
    try {
      await MembersRepository.instance.setFollowing(userId: member.id, follow: follow);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_following != null) {
          _following = _following!.map((m) => m.id == member.id ? _withFollowing(m, !follow) : m).toList();
        }
        if (_followers != null) {
          _followers = _followers!.map((m) => m.id == member.id ? _withFollowing(m, !follow) : m).toList();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't update follow status: $e")),
      );
    }
  }

  Member _withFollowing(Member m, bool following) {
    return Member(
      id: m.id,
      name: m.name,
      avatarUrl: m.avatarUrl,
      lastActive: m.lastActive,
      isFollowing: following,
      canFollow: m.canFollow,
      followerCount: m.followerCount,
      followingCount: m.followingCount,
    );
  }

  @override
  void dispose() {
    _membersController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  /// Same custom TapScale-trigger + [showFilterPopover] pattern as the
  /// Courses page's "Title (A-Z)" filter - was a native Flutter
  /// `DropdownButton` before, which opens Flutter's own default dropdown
  /// menu (a completely different render path from the shared custom
  /// popover), not this. That's what actually made this feel/look
  /// different from Courses despite both nominally being "a sort
  /// filter" - direct tester feedback.
  void _openSortPopover() {
    showFilterPopover(
      context: context,
      layerLink: _sortLayerLink,
      sections: [
        FilterSection(
          label: "Sort by",
          options: _sortOptions.entries
              .map((e) => FilterOption(
                    label: e.value,
                    selected: _membersController.sortType == e.key,
                    onTap: () => _membersController.sortBy(e.key),
                  ))
              .toList(),
        ),
      ],
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
      backgroundColor: AppColors.white,
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
                      // Was 24 - matches Home/AI Assistant/Groups' search
                      // bar size now, direct tester feedback (repeated
                      // request for consistency across pages).
                      height: 40,
                      iconSize: 18,
                      fontSize: 14,
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
                  setState(() => selectedTab = index);
                  if (index == 2 && _following == null) _loadFollowTab("following");
                  if (index == 3 && _followers == null) _loadFollowTab("followers");
                },
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
      case 2:
        return _buildFollowList(_following, "following", () => _loadFollowTab("following"));
      default:
        return _buildFollowList(_followers, "followers", () => _loadFollowTab("followers"));
    }
  }

  Widget _buildFollowList(List<Member>? members, String scope, VoidCallback onRetry) {
    if (_loadingFollowTab && members == null) {
      return const SkeletonRowList();
    }
    if (_followTabError != null && members == null) {
      return K54ErrorState(message: "Couldn't load this list.\n$_followTabError", onRetry: onRetry);
    }
    final list = members ?? [];
    if (list.isEmpty) {
      return K54EmptyState(
        icon: Icons.people_outline,
        message: scope == "following" ? "You're not following anyone yet" : "No followers yet",
      );
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () => _loadFollowTab(scope),
      child: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final member = list[index];
          return FadeSlideIn(
            key: ValueKey(member.id),
            delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
            child: ContactRow(
              avatarUrl: member.avatarUrl,
              title: member.name,
              onTap: () => _openProfile(member.id),
              trailing: PressablePill(
                label: member.isFollowing ? "Following" : "Follow",
                icon: member.isFollowing ? Icons.check : Icons.add,
                filled: member.isFollowing,
                height: 30,
                onTap: () => _toggleFollow(member, !member.isFollowing),
              ),
            ),
          );
        },
      ),
    );
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
        CompositedTransformTarget(
          link: _sortLayerLink,
          child: TapScale(
            onTap: _openSortPopover,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.groupCardAccent),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _sortOptions[_membersController.sortType] ?? _sortOptions.values.first,
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.jetBlack),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 15),
                ],
              ),
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
        child: Icon(icon, size: 15, color: selected ? AppColors.green : AppColors.grey),
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
        child: _memberCard(
          id: member.id,
          name: member.name,
          avatarUrl: member.avatarUrl,
          friendshipStatus: member.friendshipStatus,
          friendshipId: member.friendshipId,
        ),
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
                // Was 0.78 - too tight for MemberCard's full content
                // (avatar + name + 5-icon action row), squeezing it in a
                // way that made the same card look different between grid
                // and list mode - direct tester feedback ("all cards
                // should be consistent"). MemberCard itself is unchanged
                // between the two modes; only this box's proportions were
                // off.
                childAspectRatio: 0.68,
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
            child: _memberCard(
              id: f.otherUserId,
              name: f.otherUserName,
              avatarUrl: f.otherUserAvatar,
              // Everyone in this list is, by definition, an already-
              // confirmed friend - this tab only ever shows real
              // connections.
              friendshipStatus: "is_friend",
              friendshipId: f.id,
            ),
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
            child: const Text("Block", style: TextStyle(color: AppColors.error)),
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

  /// Same not_friends/pending/awaiting_response/is_friend logic as
  /// ProfileActions' Connect button - a not_friends tap sends a real
  /// request; an incoming request (awaiting_response - confirmed live
  /// 2026-07-23 as a real, distinct status string from outgoing "pending")
  /// offers Accept/Decline; an already-existing relationship offers to
  /// cancel/remove it.
  Future<void> _handleConnect(String id, String name, String friendshipStatus, String? friendshipId) async {
    if (friendshipStatus == "not_friends") {
      try {
        await FriendsRepository.instance.sendFriendRequest(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Friend request sent to $name")));
        _membersController.load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't send friend request: $e")));
      }
      return;
    }

    if (friendshipId == null) return;

    if (friendshipStatus == "awaiting_response") {
      final action = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: K54Dialog.shape,
          title: const Text("Friend request"),
          content: Text("$name sent you a friend request."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, "reject"), child: const Text("Decline")),
            TextButton(onPressed: () => Navigator.pop(dialogContext, "accept"), child: const Text("Accept")),
          ],
        ),
      );
      if (action == null) return;
      try {
        if (action == "accept") {
          await FriendsRepository.instance.acceptRequest(friendshipId);
        } else {
          await FriendsRepository.instance.rejectRequest(friendshipId);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection updated")));
          _membersController.load();
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't update friend request: $e")));
      }
      return;
    }

    final isFriend = friendshipStatus == "is_friend";
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: K54Dialog.shape,
        title: Text(isFriend ? "Remove friend" : "Cancel request"),
        content: Text(isFriend
            ? "Remove $name as a connection? You'll need to send a new request to reconnect."
            : "Cancel the pending friend request to $name?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Yes")),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (isFriend) {
        await FriendsRepository.instance.removeFriend(friendshipId);
      } else {
        await FriendsRepository.instance.cancelOutgoingRequest(friendshipId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection updated")));
        _membersController.load();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't update connection: $e")));
    }
  }

  /// Real call - resolves/creates a Better Messages thread with this
  /// member first (same call CallScreen's other entry point, chat_page.dart,
  /// relies on), then opens the same CallScreen used there.
  Future<void> _startCall(String id, String name, String? avatarUrl, {required bool isVideo}) async {
    try {
      final thread = await MessagingRepository.instance.findOrCreateThreadWith(otherUserId: id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            threadId: thread.id,
            otherUserName: name,
            otherUserAvatar: avatarUrl,
            isVideo: isVideo,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't start call: $e")));
    }
  }

  Widget _memberCard({
    required String id,
    required String name,
    String? avatarUrl,
    String friendshipStatus = "not_friends",
    String? friendshipId,
  }) {
    return MemberCard(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      friendshipStatus: friendshipStatus,
      isCurrentUser: _myUserId != null && _myUserId == id,
      onTap: () => _openProfile(id),
      onBlock: () => _blockMember(id, name),
      onConnect: () => _handleConnect(id, name, friendshipStatus, friendshipId),
      onMessage: () => _openMessage(id),
      onCall: () => _startCall(id, name, avatarUrl, isVideo: false),
      onVideoCall: () => _startCall(id, name, avatarUrl, isVideo: true),
    );
  }
}
