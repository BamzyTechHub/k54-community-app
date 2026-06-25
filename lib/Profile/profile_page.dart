import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'change_email_page.dart';
import 'change_password_page.dart';
import 'settings_page.dart';
import 'change_profile_photo_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import  'package:k54_mobile/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  //  User Data
   String userName = "";
String userEmail = "";
String userTitle = "";
String userImage = "assets/images/member1.png";

    int selectedTab = 0;

@override
void initState() {
  super.initState();
  loadUserData();
}

Future<void> loadUserData() async {

  final uid =
      FirebaseAuth.instance.currentUser!.uid;

  final doc =
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

  if (doc.exists) {

    setState(() {

      userName =
          doc["name"] ?? "";

      userEmail =
          doc["email"] ?? "";

      userTitle =
          "K54 Community Member";

    });
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

                
// ======================
// Cover Banner
// ======================

Container(

  height: 180,

  width: double.infinity,

  decoration: BoxDecoration(

    borderRadius: BorderRadius.circular(20),

    image: const DecorationImage(

      image: AssetImage(
        "assets/images/member1.png",
      ),

      fit: BoxFit.cover,

    ),

  ),

),

const SizedBox(height: 15),

// ======================
// Profile Image
// ======================

Transform.translate(

  offset: const Offset(0, -45),

  child: GestureDetector(

    onTap: () {

      Navigator.push(

        context,

        MaterialPageRoute(

          builder: (context) =>
              const ChangeProfilePhotoPage(),

        ),

      );

    },

    child: CircleAvatar(

      radius: 55,

      backgroundColor: Colors.white,

      child: CircleAvatar(

        radius: 50,

        backgroundImage: AssetImage(
          userImage,
        ),

      ),

    ),

  ),

),

// ======================
// User Name
// ======================

Text(

  userName,

  style: const TextStyle(

    fontSize: 28,

    fontWeight: FontWeight.bold,

  ),

),

const SizedBox(height: 8),

Column(
  children: [

    Text(
      userTitle,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.grey,
      ),
    ),

    const SizedBox(height: 5),

    Text(
      userEmail,
      style: const TextStyle(
        color: Colors.black54,
      ),
    ),

  ],
),

const SizedBox(height: 20),

// ======================
// Profile Stats
// ======================

Container(

  padding: const EdgeInsets.symmetric(
    vertical: 15,
  ),

  decoration: BoxDecoration(

    color: const Color(0xFFF5EFD9),

    borderRadius: BorderRadius.circular(20),

  ),

  child: Row(

    mainAxisAlignment:
        MainAxisAlignment.spaceEvenly,

    children: [

      _buildStat("245", "Followers"),

      _buildStat("89", "Following"),

      _buildStat("34", "Posts"),

    ],

  ),

),

const SizedBox(height: 25),
                
                // Action Buttons
// ======================

Row(

  mainAxisAlignment:
      MainAxisAlignment.spaceBetween,

  children: [

    // Follow

    Expanded(

      child: Container(

        height: 42,

        decoration: BoxDecoration(

          borderRadius:
              BorderRadius.circular(25),

          gradient: const LinearGradient(

            colors: [

              Color(0xFF008000),

              Color(0xFFAB8000),

              Color(0xFF008000),

            ],

          ),

        ),

        child: const Center(

          child: Row(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              Text(

                "Follow",

                style: TextStyle(

                  color: Colors.white,

                  fontWeight:
                      FontWeight.bold,

                ),

              ),

              SizedBox(width: 5),

              Icon(

                Icons.campaign,

                color: Colors.white,

                size: 18,

              ),

            ],

          ),

        ),

      ),

    ),

    const SizedBox(width: 10),

    // Edit

   Expanded(

  child: GestureDetector(

    onTap: () {

      Navigator.push(

        context,

        MaterialPageRoute(

          builder: (context) =>
              const EditProfilePage(),

        ),

      );

    },

    child: Container(

      height: 42,

      decoration: BoxDecoration(

        borderRadius:
            BorderRadius.circular(25),

        border: Border.all(

          color: const Color(0xFF008000),

        ),

      ),

      child: const Center(

        child: Row(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Text(

              "Edit",

              style: TextStyle(

                color: Colors.black,

                fontWeight:
                    FontWeight.bold,

              ),

            ),

            SizedBox(width: 5),

            Icon(

              Icons.edit,

              size: 18,

            ),

          ],

        ),

      ),

    ),

  ),

),
    // Connect

    Expanded(

      child: Container(

        height: 42,

        decoration: BoxDecoration(

          borderRadius:
              BorderRadius.circular(25),

          gradient: const LinearGradient(

            colors: [

              Color(0xFF008000),

              Color(0xFFAB8000),

              Color(0xFF008000),

            ],

          ),

        ),

        child: const Center(

          child: Row(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              Text(

                "Connect",

                style: TextStyle(

                  color: Colors.white,

                  fontWeight:
                      FontWeight.bold,

                ),

              ),

              SizedBox(width: 5),

              Icon(

                Icons.person_add,

                color: Colors.white,

                size: 18,

              ),

            ],

          ),

        ),

      ),

    ),

  ],

),

const SizedBox(height: 20),

// ======================
// Tabs
// ======================
Row(

  children: [

    Expanded(

      child: GestureDetector(

        onTap: () {

          setState(() {

            selectedTab = 0;

          });

        },

        child: Column(

          children: [

            Text(

              "Timeline",

              style: TextStyle(

                fontWeight: FontWeight.bold,

                color: selectedTab == 0
                    ? const Color(0xFF008000)
                    : Colors.grey,

              ),

            ),

            const SizedBox(height: 8),

            Container(

              height: 3,

              color: selectedTab == 0
                  ? const Color(0xFF008000)
                  : Colors.transparent,

            ),

          ],

        ),

      ),

    ),

    Expanded(

      child: GestureDetector(

        onTap: () {

          setState(() {

            selectedTab = 1;

          });

        },

        child: Column(

          children: [

            Text(

              "My Connections",

              style: TextStyle(

                fontWeight: FontWeight.bold,

                color: selectedTab == 1
                    ? const Color(0xFF008000)
                    : Colors.grey,

              ),

            ),

            const SizedBox(height: 8),

            Container(

              height: 3,

              color: selectedTab == 1
                  ? const Color(0xFF008000)
                  : Colors.transparent,

            ),

          ],

        ),

      ),

    ),

    Expanded(

      child: GestureDetector(

        onTap: () {

          setState(() {

            selectedTab = 2;

          });

        },

        child: Column(

          children: [

            Text(

              "Live Video",

              style: TextStyle(

                fontWeight: FontWeight.bold,

                color: selectedTab == 2
                    ? const Color(0xFF008000)
                    : Colors.grey,

              ),

            ),

            const SizedBox(height: 8),

            Container(

              height: 3,

              color: selectedTab == 2
                  ? const Color(0xFF008000)
                  : Colors.transparent,

            ),

          ],

        ),

      ),

    ),

     PopupMenuButton<String>(

  icon: const Icon(
    Icons.more_horiz,
  ),

  onSelected: (value) async {

    if (value == "edit") {

      Navigator.push(

        context,

        MaterialPageRoute(

          builder: (context) =>
              const EditProfilePage(),

        ),

      );

    }

    else if (value == "email") {

      Navigator.push(

        context,

        MaterialPageRoute(

          builder: (context) =>
              const ChangeEmailPage(),

        ),

      );

    }

    else if (value == "password") {

      Navigator.push(

        context,

        MaterialPageRoute(

          builder: (context) =>
              const ChangePasswordPage(),

        ),

      );

    }

    else if (value == "settings") {

      Navigator.push(

        context,

        MaterialPageRoute(

          builder: (context) =>
              const SettingsPage(),

        ),

      );

    }

       else if (value == "logout") {

  await FirebaseAuth.instance.signOut();

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const Login(),
    ),
    (route) => false,
  );

}
},

  itemBuilder: (context) => [

    const PopupMenuItem(

      value: "edit",

      child: Row(

        children: [

          Icon(Icons.edit),

          SizedBox(width: 10),

          Text("Edit Profile"),

        ],

      ),

    ),

    const PopupMenuItem(

      value: "email",

      child: Row(

        children: [

          Icon(Icons.email_outlined),

          SizedBox(width: 10),

          Text("Change Email"),

        ],

      ),

    ),

    const PopupMenuItem(

      value: "password",

      child: Row(

        children: [

          Icon(Icons.lock_outline),

          SizedBox(width: 10),

          Text("Change Password"),

        ],

      ),

    ),

    const PopupMenuItem(

      value: "settings",

      child: Row(

        children: [

          Icon(Icons.settings_outlined),

          SizedBox(width: 10),

          Text("Settings"),

        ],

      ),

    ),

    const PopupMenuItem(

      value: "logout",

      child: Row(

        children: [

          Icon(Icons.logout),

          SizedBox(width: 10),

          Text("Logout"),

        ],

      ),

    ),

  ],

),

  ],

),

const SizedBox(height: 20),

// ======================
// Timeline Post Card
// ======================
if (selectedTab == 0)

Container(

  width: double.infinity,

  padding: const EdgeInsets.all(15),

  decoration: BoxDecoration(

    color: const Color(0xFFF5EFD9),

    borderRadius: BorderRadius.circular(20),

  ),

  child: Column(

    crossAxisAlignment: CrossAxisAlignment.start,

    children: [

      // Post Header

      Row(

        children: [

          CircleAvatar(

            radius: 20,

            backgroundImage: AssetImage(
              userImage,
            ),

          ),

          const SizedBox(width: 10),

          Expanded(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(

                  userName,

                  style: const TextStyle(

                    fontWeight: FontWeight.bold,

                    fontSize: 16,

                  ),

                ),

                const Text(

                  "2 hours ago",

                  style: TextStyle(

                    color: Colors.grey,

                    fontSize: 12,

                  ),

                ),

              ],

            ),

          ),

          const Icon(
            Icons.more_vert,
          ),

        ],

      ),

      const SizedBox(height: 15),

      // Post Text

      const Text(

        "Excited to continue helping professionals build stronger communities and grow their businesses through K54!",

        style: TextStyle(

          fontSize: 15,

          height: 1.5,

        ),

      ),

      const SizedBox(height: 15),

      // Post Image

      ClipRRect(

        borderRadius: BorderRadius.circular(15),

        child: Image.asset(

          "assets/images/member1.png",

          width: double.infinity,

          height: 200,

          fit: BoxFit.cover,

        ),

      ),

      const SizedBox(height: 15),

      // Actions

      Row(

        mainAxisAlignment:
            MainAxisAlignment.spaceAround,

        children: [

          Column(

            children: [

              Icon(
                Icons.favorite_border,
                color: Colors.grey,
              ),

              SizedBox(height: 4),

              Text(
                "Like",
              ),

            ],

          ),

          Column(

            children: [

              Icon(
                Icons.chat_bubble_outline,
                color: Colors.grey,
              ),

              SizedBox(height: 4),

              Text(
                "Comment",
              ),

            ],

          ),

          Column(

            children: [

              Icon(
                Icons.repeat,
                color: Colors.grey,
              ),

              SizedBox(height: 4),

              Text(
                "Share",
              ),

            ],

          ),

        ],

      ),

    ],

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

  Widget _buildStat(
  String value,
  String label,
) {

  return Column(

    children: [

      Text(

        value,

        style: const TextStyle(

          fontSize: 20,

          fontWeight: FontWeight.bold,

        ),

      ),

      const SizedBox(height: 4),

      Text(

        label,

        style: const TextStyle(

          color: Colors.grey,

        ),

      ),

    ],

  );

}

}
