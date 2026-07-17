import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/open_profile.dart';
import 'package:k54_mobile/core/utils/responsive.dart';
import 'package:k54_mobile/core/widgets/contact_row.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/k54_search_field.dart';
import 'package:k54_mobile/core/widgets/skeleton_loaders.dart';
import 'package:k54_mobile/core/widgets/state_views.dart';
import 'package:k54_mobile/features/friends/controllers/friends_controller.dart';
import 'package:k54_mobile/features/friends/models/friendship_model.dart';
import 'package:k54_mobile/features/friends/repositories/friends_repository.dart';

/// Friends list header + row layout match the K54 Figma file exactly
/// (node 50:1005 "Friends", measured 2026-07-08): back button, title,
/// search/video-call/call icons in the header; avatar + name + call/
/// video/profile icons per row, no "Online/Offline" text, no per-row
/// Add/Remove-friend button (Figma has none - remove is a long-press
/// action instead, see _friendTile).
///
/// One deliberate deviation from the measured design: Figma shows a
/// green online-status dot on every avatar, but the app has no real
/// presence data source wired up yet (BuddyBoss's Heartbeat-based
/// presence isn't implemented anywhere in this codebase) - showing it
/// unconditionally would be the same "fake status" problem already
/// fixed elsewhere in this app, so it's omitted until presence is real.
///
/// The Requests tab (incoming/outgoing) has no Figma screen at all -
/// kept as a flagged, functional-but-unstyled addition since friend
/// requests are a real backend concept, pending a real design.
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FriendsListController _listController = FriendsListController();
  final FriendsRequestsController _requestsController = FriendsRequestsController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Collapsed by default, same fix as Messages' header - the field only
  // appears after tapping the search icon rather than being permanently
  // visible.
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _listController.addListener(() => setState(() {}));
    _requestsController.addListener(() => setState(() {}));
    _listController.load();
    _requestsController.load();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
        setState(() => _searchExpanded = false);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _listController.loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _listController.dispose();
    _requestsController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showNotAvailable(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst("UnimplementedError: ", ""))),
    );
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature is coming soon")),
    );
  }

  // The header search icon lives outside the TabBarView, but the actual
  // search field only renders on the Friends tab - switch there first
  // (if the Requests tab is active) so focus lands on a field that
  // actually exists, instead of silently doing nothing.
  void _focusSearch() {
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
    setState(() => _searchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocusNode.requestFocus());
  }

  Future<void> _accept(Friendship f) async {
    try {
      await FriendsRepository.instance.acceptRequest(f.id);
      _requestsController.load();
    } catch (e) {
      _showNotAvailable(e);
    }
  }

  Future<void> _reject(Friendship f) async {
    try {
      await FriendsRepository.instance.rejectRequest(f.id);
      _requestsController.load();
    } catch (e) {
      _showNotAvailable(e);
    }
  }

  Future<void> _cancel(Friendship f) async {
    try {
      await FriendsRepository.instance.cancelOutgoingRequest(f.id);
      _requestsController.load();
    } catch (e) {
      _showNotAvailable(e);
    }
  }

  void _openProfile(String userId) {
    openProfile(context, userId);
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
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
    final pendingCount = _requestsController.incoming.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  _iconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  Text(
                    "Friends",
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.jetBlack,
                    ),
                  ),
                  const Spacer(),
                  // Only a search icon exists in the real header (node
                  // 50:1005) - re-verified directly against the raw JSON
                  // 2026-07-16. The videocam/call/more_vert icons here
                  // were an unverified assumption carried over from a
                  // different screen's header and were fake stubs anyway;
                  // removed rather than left as dead UI. Tapping search
                  // focuses the real search field below (switching to the
                  // Friends tab first if needed) instead of showing its
                  // own "coming soon" next to a field that already works.
                  GestureDetector(
                    onTap: _focusSearch,
                    child: const Icon(Icons.search, size: 18, color: AppColors.jetBlack),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.green,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.green,
                tabs: [
                  const Tab(text: "Friends"),
                  Tab(text: pendingCount > 0 ? "Requests ($pendingCount)" : "Requests"),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFriendsTab(),
                    _buildRequestsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _searchExpanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: K54SearchField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _listController.search,
                    hintText: "Search friends...",
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Expanded(child: _buildFriendsBody()),
      ],
    );
  }

  Widget _buildFriendsBody() {
    if (_listController.loading && _listController.friends.isEmpty) {
      return const SkeletonRowList();
    }
    if (_listController.error != null && _listController.friends.isEmpty) {
      return K54ErrorState(
        message: "Couldn't load friends.\n${_listController.error}",
        onRetry: _listController.load,
      );
    }

    final friends = _listController.friends;
    if (friends.isEmpty) {
      return RefreshIndicator(
        color: AppColors.green,
        onRefresh: _listController.load,
        child: ListView(
          children: const [
            SizedBox(height: 100),
            K54EmptyState(icon: Icons.person_add_alt_outlined, message: "No friends yet"),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _listController.load,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.isTablet(context) ? 640 : double.infinity),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: friends.length + (_listController.loadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= friends.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
                    ),
                  ),
                );
              }
              return _friendTile(friends[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _friendTile(Friendship f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ContactRow(
        avatarUrl: f.otherUserAvatar,
        title: f.otherUserName,
        onTap: () => _openProfile(f.otherUserId),
        onLongPress: () => _removeFriendConfirm(f),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _iconButton(icon: Icons.call_outlined, onTap: () => _comingSoon("Voice calling")),
            const SizedBox(width: 8),
            _iconButton(icon: Icons.videocam_outlined, onTap: () => _comingSoon("Video calling")),
            const SizedBox(width: 8),
            _iconButton(
              icon: Icons.person_outline,
              onTap: () => _openProfile(f.otherUserId),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFriendConfirm(Friendship f) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: K54Dialog.shape,
        title: const Text("Remove friend"),
        content: Text("Remove ${f.otherUserName} from your friends?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FriendsRepository.instance.removeFriend(f.id);
      _listController.load();
    } catch (e) {
      _showNotAvailable(e);
    }
  }

  Widget _buildRequestsTab() {
    if (_requestsController.loading) {
      return const SkeletonRowList();
    }
    if (_requestsController.error != null) {
      return K54ErrorState(
        message: "Couldn't load requests.\n${_requestsController.error}",
        onRetry: _requestsController.load,
      );
    }

    final incoming = _requestsController.incoming;
    final outgoing = _requestsController.outgoing;

    if (incoming.isEmpty && outgoing.isEmpty) {
      return RefreshIndicator(
        color: AppColors.green,
        onRefresh: _requestsController.load,
        child: ListView(
          children: const [
            SizedBox(height: 100),
            K54EmptyState(icon: Icons.mark_email_unread_outlined, message: "No pending requests"),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: _requestsController.load,
      child: ListView(
        children: [
          if (incoming.isNotEmpty) ...[
            const Text("Incoming", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...incoming.map((f) => _requestTile(
                  f,
                  actions: [
                    TextButton(
                      onPressed: () => _accept(f),
                      child: const Text("Accept", style: TextStyle(color: AppColors.green)),
                    ),
                    TextButton(
                      onPressed: () => _reject(f),
                      child: const Text("Reject", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                )),
            const SizedBox(height: 20),
          ],
          if (outgoing.isNotEmpty) ...[
            const Text("Sent", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...outgoing.map((f) => _requestTile(
                  f,
                  actions: [
                    TextButton(
                      onPressed: () => _cancel(f),
                      child: const Text("Cancel", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                )),
          ],
        ],
      ),
    );
  }

  Widget _requestTile(Friendship f, {required List<Widget> actions}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ContactRow(
        avatarUrl: f.otherUserAvatar,
        title: f.otherUserName,
        titleStyle: const TextStyle(fontWeight: FontWeight.w600),
        onTap: () => _openProfile(f.otherUserId),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: actions),
      ),
    );
  }
}
