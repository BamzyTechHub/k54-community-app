import 'package:flutter/material.dart';

class ChangeEmailPage extends StatefulWidget {

  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() =>
      _ChangeEmailPageState();

}

class _ChangeEmailPageState
    extends State<ChangeEmailPage> {

  final TextEditingController
      currentEmailController =
      TextEditingController(
    text: "evelyn@email.com",
  );

  final TextEditingController
      newEmailController =
      TextEditingController();

  final TextEditingController
      confirmEmailController =
      TextEditingController();

  @override
  void dispose() {

    currentEmailController.dispose();
    newEmailController.dispose();
    confirmEmailController.dispose();

    super.dispose();

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

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Row(

                  children: [

                    IconButton(

                      onPressed: () {

                        Navigator.pop(context);

                      },

                      icon: const Icon(
                        Icons.arrow_back,
                      ),

                    ),

                    const SizedBox(width: 10),

                    const Text(

                      "Change Email",

                      style: TextStyle(

                        fontSize: 24,

                        fontWeight:
                            FontWeight.bold,

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 30),

                const Text(

                  "Current Email",

                  style: TextStyle(

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

                const SizedBox(height: 8),

                TextField(

                  controller:
                      currentEmailController,

                  readOnly: true,

                  decoration: InputDecoration(

                    filled: true,

                    fillColor:
                        const Color(0xFFF5EFD9),

                    border:
                        OutlineInputBorder(

                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),

                    ),

                  ),

                ),

                const SizedBox(height: 20),

                const Text(

                  "New Email",

                  style: TextStyle(

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

                const SizedBox(height: 8),

                TextField(

                  controller:
                      newEmailController,

                  keyboardType:
                      TextInputType.emailAddress,

                  decoration: InputDecoration(

                    hintText:
                        "Enter new email",

                    filled: true,

                    fillColor:
                        const Color(0xFFF5EFD9),

                    border:
                        OutlineInputBorder(

                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),

                    ),

                  ),

                ),

                const SizedBox(height: 20),

                const Text(

                  "Confirm Email",

                  style: TextStyle(

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

                const SizedBox(height: 8),

                TextField(

                  controller:
                      confirmEmailController,

                  keyboardType:
                      TextInputType.emailAddress,

                  decoration: InputDecoration(

                    hintText:
                        "Confirm new email",

                    filled: true,

                    fillColor:
                        const Color(0xFFF5EFD9),

                    border:
                        OutlineInputBorder(

                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),

                    ),

                  ),

                ),
                const SizedBox(height: 25),

// ======================
// Verification Notice
// ======================

Container(

  padding: const EdgeInsets.all(15),

  decoration: BoxDecoration(

    color: const Color(0xFFF5EFD9),

    borderRadius: BorderRadius.circular(15),

  ),

  child: const Row(

    crossAxisAlignment:
        CrossAxisAlignment.start,

    children: [

      Icon(

        Icons.info_outline,

        color: Color(0xFF008000),

      ),

      SizedBox(width: 10),

      Expanded(

        child: Text(

          "A verification link will be sent to your new email address before changes are applied.",

          style: TextStyle(
            fontSize: 14,
          ),

        ),

      ),

    ],

  ),

),

const SizedBox(height: 30),

// ======================
// Verify Email Button
// ======================

SizedBox(

  width: double.infinity,

  height: 55,

  child: OutlinedButton(

    onPressed: () {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Verification email sent",
          ),

        ),

      );

    },

    style: OutlinedButton.styleFrom(

      side: const BorderSide(
        color: Color(0xFF008000),
      ),

      shape: RoundedRectangleBorder(

        borderRadius:
            BorderRadius.circular(15),

      ),

    ),

    child: const Text(

      "Verify Email",

      style: TextStyle(

        color: Color(0xFF008000),

        fontWeight:
            FontWeight.bold,

      ),

    ),

  ),

),

const SizedBox(height: 15),

// ======================
// Update Email Button
// ======================

SizedBox(

  width: double.infinity,

  height: 55,

  child: ElevatedButton(

    onPressed: () {

      if (newEmailController.text
              .trim()
              .isEmpty ||
          confirmEmailController.text
              .trim()
              .isEmpty) {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              "Please fill all fields",
            ),

          ),

        );

        return;

      }

      if (newEmailController.text !=
          confirmEmailController.text) {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              "Emails do not match",
            ),

          ),

        );

        return;

      }

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Email updated successfully",
          ),

        ),

      );

    },

    style: ElevatedButton.styleFrom(

      backgroundColor:
          const Color(0xFF008000),

      shape: RoundedRectangleBorder(

        borderRadius:
            BorderRadius.circular(15),

      ),

    ),

    child: const Text(

      "Update Email",

      style: TextStyle(

        color: Colors.white,

        fontWeight:
            FontWeight.bold,

      ),

    ),

  ),

),

const SizedBox(height: 30),
],

            ),

          ),

        ),

      ),

    );

  }

}