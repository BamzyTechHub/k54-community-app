import 'package:flutter/material.dart';
import 'package:k54_mobile/features/profile/screens/edit_profile_page.dart';
import 'package:k54_mobile/features/profile/screens/change_email_page.dart';
import 'package:k54_mobile/features/profile/screens/change_password_page.dart';
import 'package:k54_mobile/features/profile/screens/settings_page.dart';
import 'package:k54_mobile/features/profile/screens/logout_page.dart';
import 'package:k54_mobile/features/profile/widgets/profile_header.dart';
import 'package:k54_mobile/features/profile/widgets/profile_stats.dart';
import 'package:k54_mobile/features/profile/widgets/profile_actions.dart';
import 'package:k54_mobile/features/profile/widgets/profile_tabs.dart';
import 'package:k54_mobile/features/profile/widgets/profile_placeholder_tabs.dart';
import 'package:k54_mobile/features/activity/screens/timeline_page.dart';
import 'package:k54_mobile/features/groups/screens/groups_page.dart';
import 'package:k54_mobile/features/live_video/screens/go_live_page.dart';
import 'package:k54_mobile/features/friends/models/friendship_model.dart';
import 'package:k54_mobile/features/friends/repositories/friends_repository.dart';
import 'package:k54_mobile/features/messaging/repositories/messaging_repository.dart';
import 'package:k54_mobile/features/messaging/screens/chat_page.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/utils/responsive.dart';
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
    int selectedTab = 0;

List<Friendship> _connections = [];
bool _loadingConnections = true;
String? _connectionsError;

@override
void initState() {
  super.initState();
  loadUserData();
  _loadConnections();
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

void _comingSoon(String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("$feature is coming soon")),
  );
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
        onTap: () => _openProfile(f.otherUserId),
        onBlock: () => _comingSoon("Block"),
        onConnect: () => _comingSoon("Connect"),
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

Widget _liveVideoTab(BuildContext context) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: const Color(0xFFF5EFD9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Text(
          "No live videos yet",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoLivePage()),
          ),
          icon: const Icon(Icons.videocam_outlined, color: AppColors.green),
          label: const Text("Go Live", style: TextStyle(color: AppColors.green)),
        ),
      ],
    ),
  );
}

Future loadUserData() async {
  try {
    final response = widget.userId == null
    ? await AuthService().getCurrentUser()
    : await AuthService().getMember(widget.userId!);
    final user = response.data;
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
  posts = user["total_post_count"] ?? 0;
});
  } catch (e) {
    debugPrint(e.toString());
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
),
const SizedBox(height: 20),
ProfileTabs(
  selectedIndex: selectedTab,
  onTabChanged: (index) {
    setState(() {
      selectedTab = index;
    });
  },
   onMenuPressed: (value) async {
  switch (value) {
    case "edit":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EditProfilePage(),
        ),
      );
      break;
    case "email":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChangeEmailPage(),
        ),
      );
      break;
    case "password":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChangePasswordPage(),
        ),
      );
      break;
    case "settings":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SettingsPage(),
        ),
      );
      break;
    case "logout":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LogoutPage(),
        ),
      );
      break;
  }
},
),
const SizedBox(height: 20),
if (selectedTab == 0)
   SizedBox(
    height: _embeddedTabHeight(context),
    child: TimelinePage(
    userId: widget.userId,
),
  ),

if (selectedTab == 1) _buildConnectionsTab(),
if (selectedTab == 2) _liveVideoTab(context),
if (selectedTab == 3)
  SizedBox(
    height: _embeddedTabHeight(context),
    child: GroupsPage(embedded: true),
  ),
if (selectedTab == 4) const ProfileCoursesTab(),
if (selectedTab == 5) const ProfileDocumentsTab(),
if (selectedTab == 6) const ProfileEmptyTab(icon: Icons.quiz_outlined, message: "No quizzes yet"),
if (selectedTab == 7) const ProfileOrdersTab(),
const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
