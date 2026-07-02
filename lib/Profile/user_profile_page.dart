import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProfilePage extends StatelessWidget {

  final UserModel user;

const UserProfilePage({
  super.key,
  required this.user,
});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

      body: SafeArea(

        child: SingleChildScrollView(

          child: Column(

            children: [
Positioned(
  top: 15,
  left: 15,
  child: IconButton(
    onPressed: () {
      Navigator.pop(context);
    },
    icon: const Icon(
      Icons.arrow_back,
      color: Colors.white,
    ),
  ),
),
              // Cover

              Container(

                height: 180,

                width: double.infinity,

                decoration: const BoxDecoration(

                  gradient: LinearGradient(

                    colors: [

                      Color(0xFF008000),

                      Color(0xFFAB8000),

                    ],

                  ),

                ),

              ),

              Transform.translate(

                offset: const Offset(0, -50),

                child: Column(

                  children: [

                    CircleAvatar(

                      radius: 55,

                      backgroundImage: AssetImage(user.profileImage),

                    ),

                    const SizedBox(height: 10),

                    Text(

                      user.username,

                      style: const TextStyle(

                        fontSize: 24,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                    const SizedBox(height: 5),

                    Text(

                      user.bio,

                      textAlign: TextAlign.center,

                      style: const TextStyle(

                        color: Colors.grey,

                      ),

                    ),

                  ],

                ),

              ),

              Container(

                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                padding: const EdgeInsets.all(15),

                decoration: BoxDecoration(

                  color: const Color(0xFFF5EFD9),

                  borderRadius:
                      BorderRadius.circular(20),

                ),

                child: const Row(

                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,

                  children: [

                    Column(
                      children: [
                        Text(
                          "245",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text("Followers"),
                      ],
                    ),

                    Column(
                      children: [
                        Text(
                          "89",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text("Following"),
                      ],
                    ),

                    Column(
                      children: [
                        Text(
                          "34",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text("Posts"),
                      ],
                    ),

                  ],

                ),

              ),

              const SizedBox(height: 20),

              Padding(

                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                child: Row(

                  children: [

                    Expanded(

                      child: ElevatedButton(

                        onPressed: () {},

                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF008000),
                        ),

                        child: const Text(
                          "Follow",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),

                      ),

                    ),

                    const SizedBox(width: 10),

                    Expanded(

                      child: OutlinedButton(

                        onPressed: () {},

                        child: const Text(
                          "Message",
                        ),

                      ),

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 30),

              const Divider(),

const Padding(
  padding: EdgeInsets.all(20),
  child: Align(
    alignment: Alignment.centerLeft,
    child: Text(
      "Posts",
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),

            ],

          ),

        ),

      ),

    );

  }

}