import 'package:flutter/material.dart';

import 'package:k54_mobile/features/friends/controllers/friends_controller.dart';
import 'package:k54_mobile/features/friends/models/friendship_model.dart';
import 'package:k54_mobile/features/friends/repositories/friends_repository.dart';
import 'package:k54_mobile/features/profile/screens/profile_page.dart';

/// No Figma reference exists yet for Friends - this keeps the app's
/// existing color/typography language (green/cream card palette used
/// throughout Activity/Messaging/Groups) as a placeholder shell around
/// real data and state, rather than inventing a new visual design. The
/// Friends/Requests tab split is a structural necessity (BuddyBoss's
/// confirmed friendship model has a pending state with a direction, see
/// friendship_model.dart), not a stylistic choice - revisit the visuals
/// once Figma is available.
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with SingleTickerProviderStateMixin {
  static const _brandGreen = Color(0xFF008000);
  static const _cardBackground = Color(0xFFF5EFD9);

  late final TabController _tabController;
  final FriendsListController _listController = FriendsListController();
  final FriendsRequestsController _requestsController = FriendsRequestsController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _listController.addListener(() => setState(() {}));
    _requestsController.addListener(() => setState(() {}));
    _listController.load();
    _requestsController.load();
    _scrollController.addListener(_onScroll);
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
    _scrollController.dispose();
    super.dispose();
  }

  void _showNotAvailable(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst("UnimplementedError: ", ""))),
    );
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _requestsController.incoming.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    "Friends",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      _listController.load();
                      _requestsController.load();
                    },
                    icon: const Icon(Icons.refresh, size: 26),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                labelColor: _brandGreen,
                unselectedLabelColor: Colors.grey,
                indicatorColor: _brandGreen,
                tabs: [
                  const Tab(text: "Friends"),
                  Tab(text: pendingCount > 0 ? "Requests ($pendingCount)" : "Requests"),
                ],
              ),
              const SizedBox(height: 12),
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
        TextField(
          controller: _searchController,
          onChanged: _listController.search,
          decoration: InputDecoration(
            hintText: "Search friends...",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildFriendsBody()),
      ],
    );
  }

  Widget _buildFriendsBody() {
    if (_listController.loading && _listController.friends.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _brandGreen));
    }
    if (_listController.error != null && _listController.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load friends.\n${_listController.error}", textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: _listController.load, child: const Text("Retry")),
          ],
        ),
      );
    }

    final friends = _listController.friends;
    if (friends.isEmpty) {
      return RefreshIndicator(
        color: _brandGreen,
        onRefresh: _listController.load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text("No friends yet")),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _brandGreen,
      onRefresh: _listController.load,
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: _brandGreen),
                ),
              ),
            );
          }
          return _friendTile(friends[index]);
        },
      ),
    );
  }

  Widget _friendTile(Friendship f) {
    return InkWell(
      onTap: () => _openProfile(f.otherUserId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  f.otherUserAvatar != null ? NetworkImage(f.otherUserAvatar!) : null,
              child: f.otherUserAvatar == null
                  ? Text(f.otherUserName.isNotEmpty ? f.otherUserName[0].toUpperCase() : "?")
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                f.otherUserName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: () => _removeFriendConfirm(f),
              icon: const Icon(Icons.person_remove_outlined, color: Colors.black54),
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
      return const Center(child: CircularProgressIndicator(color: _brandGreen));
    }
    if (_requestsController.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load requests.\n${_requestsController.error}",
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: _requestsController.load, child: const Text("Retry")),
          ],
        ),
      );
    }

    final incoming = _requestsController.incoming;
    final outgoing = _requestsController.outgoing;

    if (incoming.isEmpty && outgoing.isEmpty) {
      return RefreshIndicator(
        color: _brandGreen,
        onRefresh: _requestsController.load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text("No pending requests")),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _brandGreen,
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
                      child: const Text("Accept", style: TextStyle(color: _brandGreen)),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _openProfile(f.otherUserId),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    f.otherUserAvatar != null ? NetworkImage(f.otherUserAvatar!) : null,
                child: f.otherUserAvatar == null
                    ? Text(f.otherUserName.isNotEmpty ? f.otherUserName[0].toUpperCase() : "?")
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(f.otherUserName, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}
