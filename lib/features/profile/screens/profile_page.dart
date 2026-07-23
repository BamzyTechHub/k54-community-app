import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:k54_mobile/features/profile/screens/settings_page.dart';
import 'package:k54_mobile/features/profile/screens/email_invites_page.dart';
import 'package:k54_mobile/features/profile/widgets/profile_header.dart';
import 'package:k54_mobile/features/profile/widgets/profile_stats.dart';
import 'package:k54_mobile/features/profile/widgets/profile_actions.dart';
import 'package:k54_mobile/features/profile/widgets/profile_tabs.dart';
import 'package:k54_mobile/features/profile/widgets/profile_placeholder_tabs.dart';
import 'package:k54_mobile/features/activity/screens/timeline_page.dart';
import 'package:k54_mobile/features/groups/screens/groups_page.dart';
import 'package:k54_mobile/features/live_video/widgets/profile_live_video_tab.dart';
import 'package:k54_mobile/features/friends/models/friendship_model.dart';
import 'package:k54_mobile/features/friends/repositories/friends_repository.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
import 'package:k54_mobile/features/messaging/screens/chat_page.dart';
import 'package:k54_mobile/features/messaging/widgets/messages_inbox_list.dart';
import 'package:k54_mobile/core/services/buddyboss_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/utils/k54_route.dart';
import 'package:k54_mobile/core/utils/open_profile.dart';
import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/utils/responsive.dart';
import 'package:k54_mobile/core/widgets/bottom_navigation.dart';
import 'package:k54_mobile/core/widgets/k54_dialog.dart';
import 'package:k54_mobile/core/widgets/member_card.dart';


class ProfilePage extends StatefulWidget {
  final String? userId;

  const ProfilePage({
    super.key,
    this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  //  User Data
   String userName = "";
String userEmail = "";
String userTitle = "";
String userImage = "";
int followers = 0;
int following = 0;
int posts = 0;
bool isFollowingProfile = false;
String friendshipStatus = "not_friends";
String? friendshipId;

// The sliding tab-window state - see ProfileTabs' doc comment for the
// full model. Starts on the base 3; picking a hidden tab from "..."
// slides it into this window and makes it active.
List<String> _visibleTabs = List.of(ProfileTabs.baseTabs);
String _activeTab = ProfileTabs.baseTabs.first;

List<Friendship> _connections = [];
bool _loadingConnections = true;
String? _connectionsError;

// Hides the bottom nav on scroll-down, brings it back on scroll-up -
// the user explicitly asked for it not to just sit there as a static
// bar. Threshold-based (not every pixel) so tiny scroll jitter doesn't
// flicker it.
final ScrollController _scrollController = ScrollController();
bool _navVisible = true;
double _lastScrollOffset = 0;
static const _scrollHideThreshold = 12.0;

@override
void initState() {
  super.initState();
  loadUserData();
  _loadConnections();
  _scrollController.addListener(_onScroll);
}

void _onScroll() {
  final offset = _scrollController.offset;
  final delta = offset - _lastScrollOffset;
  if (delta.abs() < _scrollHideThreshold) return;

  final shouldBeVisible = delta < 0; // scrolling up -> show, down -> hide
  if (shouldBeVisible != _navVisible) {
    setState(() => _navVisible = shouldBeVisible);
  }
  _lastScrollOffset = offset;
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
  _scrollController.removeListener(_onScroll);
  _scrollController.dispose();
  super.dispose();
}

void _openProfile(String userId) {
  openProfile(context, userId);
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

void _comingSoon(String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("$feature is coming soon")),
  );
}

Future<void> _removeConnection(Friendship f) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: K54Dialog.shape,
      title: const Text("Remove connection"),
      content: Text("Remove ${f.otherUserName}? You'll need to send a new request to reconnect."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text("Remove", style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await FriendsRepository.instance.removeFriend(f.id);
    if (!mounted) return;
    setState(() => _connections.removeWhere((c) => c.id == f.id));
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't remove connection: $e")));
  }
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

Widget _buildConnectionsTab() {
  if (_loadingConnections) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: CircularProgressIndicator(color: AppColors.green)),
    );
  }
  if (_connectionsError != null) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text("Couldn't load connections.\n$_connectionsError", textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: _loadConnections, child: const Text("Retry")),
        ],
      ),
    );
  }
  if (_connections.isEmpty) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: Text("No connections yet")),
    );
  }

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _connections.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: Responsive.gridColumns(context),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.78,
    ),
    itemBuilder: (context, index) {
      final f = _connections[index];
      return MemberCard(
        id: f.otherUserId,
        name: f.otherUserName,
        avatarUrl: f.otherUserAvatar,
        // Everyone in this list is, by definition, an already-confirmed
        // friend - drives the connect icon showing "Remove Connection"
        // (matching the real site's own card) instead of the default
        // "Connect" icon.
        friendshipStatus: "is_friend",
        onTap: () => _openProfile(f.otherUserId),
        onBlock: () => _blockMember(f.otherUserId, f.otherUserName),
        // These are already-established connections (this tab lists real
        // friendships, not suggestions), so "Connect" here offers to undo
        // it rather than being a dead "coming soon" stub - direct tester
        // feedback ("the connect button isn't working yet").
        onConnect: () => _removeConnection(f),
        onMessage: () => _openMessage(f.otherUserId),
        onCall: () => _comingSoon("Voice call"),
        onVideoCall: () => _comingSoon("Video call"),
      );
    },
  );
}

/// The Timeline/Groups tabs are embedded scrollables nested inside this
/// page's own SingleChildScrollView, so they need a bounded height rather
/// than Expanded. A flat 600px clipped tablets (wasted space on a taller
/// viewport) and could clip short phones - sizing off the actual screen
/// height fixes both.
double _embeddedTabHeight(BuildContext context) {
  return (MediaQuery.sizeOf(context).height * 0.75).clamp(500, 1400);
}

Future loadUserData() async {
  try {
    final response = widget.userId == null
    ? await AuthService().getCurrentUser()
    : await AuthService().getMember(widget.userId!);
    final user = response.data;
    final resolvedUserId = widget.userId ?? (user["id"]?.toString() ?? "");
    setState(() {
  userName = user["name"] ?? "";
  userEmail = user["user_login"] ?? "";
  userImage =
      user["avatar_urls"]?["full"] ??
      user["avatar_urls"]?["thumb"] ??
      "assets/images/member1.png";
  userTitle =
      user["xprofile"]?["groups"]?["1"]?["fields"]?["31"]?["value"]?["raw"] ??
      "K54 Community Member";
  followers = user["followers"] ?? 0;
  following = user["following"] ?? 0;
  isFollowingProfile = user["is_following"] == true;
  friendshipStatus = (user["friendship_status"] ?? "not_friends").toString();
  friendshipId = user["friendship_id"]?.toString();
});
    // Separate call, not a field on the member response - see
    // BuddyBossService.getUserPostCount's doc comment for why
    // total_post_count never worked.
    if (resolvedUserId.isNotEmpty) {
      try {
        final count = await BuddyBossService().getUserPostCount(resolvedUserId);
        if (mounted && count != null) setState(() => posts = count);
      } catch (_) {
        // Non-fatal - stat just stays at 0 rather than blocking the rest
        // of the profile from loading.
      }
    }
  } catch (e) {
    debugPrint(e.toString());
  }
}
  void _onTabTapped(String tab) {
    setState(() => _activeTab = tab);
  }

  /// Called when a hidden tab is picked from the "..." menu. Account
  /// Settings is the one exception that pushes a real page instead of
  /// sliding into the tab window - see ProfileTabs' doc comment.
  void _onMenuSelected(String label) {
    if (label == "Account Settings") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
      return;
    }
    setState(() {
      _visibleTabs = [..._visibleTabs.sublist(1), label];
      _activeTab = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      // Not one of the 5 tracked bottom-nav destinations, so no icon
      // claims "active" - an out-of-range index keeps every icon in its
      // plain inactive state rather than falsely highlighting one.
      // Slides away on scroll-down, slides back on scroll-up (see
      // _onScroll) instead of sitting there as a static bar.
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        offset: _navVisible ? Offset.zero : const Offset(0, 1),
        child: const K54BottomNavigation(currentIndex: -1),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            child: Column(
              children: [
                // ======================
                // Header
                // ======================
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Small page-level label above the profile card,
                    // matching the current tab (Timeline/My Connections/
                    // live Video) - same convention as the small grey
                    // title Messages/Members/Groups show at their own
                    // page top.
                    Text(
                      _activeTab,
                      style: GoogleFonts.lato(fontSize: 14, color: AppColors.greyShade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ProfileHeader(
  userName: userName,
  userTitle: userTitle,
  userImage: userImage,
),
ProfileStats(
  followers: followers,
  following: following,
  posts: posts,
),

     const SizedBox(height: 20),
ProfileActions(
  isCurrentUser: widget.userId == null,
  otherUserId: widget.userId,
  isFollowing: isFollowingProfile,
  onFollowChanged: (value) => setState(() => isFollowingProfile = value),
  friendshipStatus: friendshipStatus,
  friendshipId: friendshipId,
),
const SizedBox(height: 20),
ProfileTabs(
  visibleTabs: _visibleTabs,
  activeTab: _activeTab,
  onTabChanged: _onTabTapped,
  onMenuPressed: _onMenuSelected,
),
const SizedBox(height: 20),
if (_activeTab == "Timeline")
   SizedBox(
    height: _embeddedTabHeight(context),
    child: TimelinePage(
    userId: widget.userId,
),
  ),
if (_activeTab == "My Connections") _buildConnectionsTab(),
if (_activeTab == "live Video") ProfileLiveVideoTab(userId: widget.userId),
if (_activeTab == "Groups")
  SizedBox(
    height: _embeddedTabHeight(context),
    child: GroupsPage(embedded: true),
  ),
if (_activeTab == "Messages") const MessagesInboxList(),
if (_activeTab == "Courses") ProfileCoursesTab(userId: widget.userId),
if (_activeTab == "Documents") const ProfileDocumentsTab(),
if (_activeTab == "Email Invites") const EmailInvitesForm(),
const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
