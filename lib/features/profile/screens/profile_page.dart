import 'package:flutter/material.dart';
import 'package:k54_mobile/features/profile/screens/edit_profile_page.dart';
import 'package:k54_mobile/features/profile/screens/change_email_page.dart';
import 'package:k54_mobile/features/profile/screens/change_password_page.dart';
import 'package:k54_mobile/features/profile/screens/settings_page.dart';
import 'package:k54_mobile/features/auth/screens/login.dart';
import 'package:k54_mobile/features/profile/widgets/profile_header.dart';
import 'package:k54_mobile/features/profile/widgets/profile_stats.dart';
import 'package:k54_mobile/features/profile/widgets/profile_actions.dart';
import 'package:k54_mobile/features/profile/widgets/profile_tabs.dart';
import 'package:k54_mobile/features/activity/screens/timeline_page.dart';
import 'package:k54_mobile/core/services/auth_service.dart';


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
String userImage = "assets/images/member1.png";
int followers = 0;
int following = 0;
int posts = 0;
    int selectedTab = 0;
@override
void initState() {
  super.initState();
  loadUserData();
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
  userEmail: userEmail,
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
      await AuthService().logout();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const Login(),
        ),
        (route) => false,
      );
      break;
  }
},
),
const SizedBox(height: 20),
if (selectedTab == 0)
   SizedBox(
    height: 600,
    child: TimelinePage(
    userId: widget.userId,
),
  ),
 
if (selectedTab == 1)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: const Color(0xFFF5EFD9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Center(
      child: Text(
        "My Connections Coming Soon",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
if (selectedTab == 2)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: const Color(0xFFF5EFD9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Center(
      child: Text(
        "Live Videos Coming Soon",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
