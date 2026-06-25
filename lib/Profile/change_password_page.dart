import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {

  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() =>
      _ChangePasswordPageState();

}

class _ChangePasswordPageState
    extends State<ChangePasswordPage> {

  final TextEditingController
      currentPasswordController =
      TextEditingController();

  final TextEditingController
      newPasswordController =
      TextEditingController();

  final TextEditingController
      confirmPasswordController =
      TextEditingController();

  bool hideCurrentPassword = true;

  bool hideNewPassword = true;

  bool hideConfirmPassword = true;

  @override
  void dispose() {

    currentPasswordController.dispose();

    newPasswordController.dispose();

    confirmPasswordController.dispose();

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
                      ),

                    ),

                    const SizedBox(width: 10),

                    const Text(

                      "Change Password",

                      style: TextStyle(

                        fontSize: 24,

                        fontWeight:
                            FontWeight.bold,

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 30),

                // ======================
                // Current Password
                // ======================

                const Text(

                  "Current Password",

                  style: TextStyle(

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

                const SizedBox(height: 8),

                TextField(

                  controller:
                      currentPasswordController,

                  obscureText:
                      hideCurrentPassword,

                  decoration: InputDecoration(

                    hintText:
                        "Enter current password",

                    filled: true,

                    fillColor:
                        const Color(0xFFF5EFD9),

                    suffixIcon: IconButton(

                      onPressed: () {

                        setState(() {

                          hideCurrentPassword =
                              !hideCurrentPassword;

                        });

                      },

                      icon: Icon(

                        hideCurrentPassword
                            ? Icons.visibility_off
                            : Icons.visibility,

                      ),

                    ),

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

                // ======================
                // New Password
                // ======================

                const Text(

                  "New Password",

                  style: TextStyle(

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

                const SizedBox(height: 8),

                TextField(

                  controller:
                      newPasswordController,

                  obscureText:
                      hideNewPassword,

                  decoration: InputDecoration(

                    hintText:
                        "Enter new password",

                    filled: true,

                    fillColor:
                        const Color(0xFFF5EFD9),

                    suffixIcon: IconButton(

                      onPressed: () {

                        setState(() {

                          hideNewPassword =
                              !hideNewPassword;

                        });

                      },

                      icon: Icon(

                        hideNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,

                      ),

                    ),

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

                // ======================
                // Confirm Password
                // ======================

                const Text(

                  "Confirm Password",

                  style: TextStyle(

                    fontWeight:
                        FontWeight.bold,

                  ),

                ),

                const SizedBox(height: 8),

                TextField(

                  controller:
                      confirmPasswordController,

                  obscureText:
                      hideConfirmPassword,

                  decoration: InputDecoration(

                    hintText:
                        "Confirm password",

                    filled: true,

                    fillColor:
                        const Color(0xFFF5EFD9),

                    suffixIcon: IconButton(

                      onPressed: () {

                        setState(() {

                          hideConfirmPassword =
                              !hideConfirmPassword;

                        });

                      },

                      icon: Icon(

                        hideConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,

                      ),

                    ),

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
// Password Requirements
// ======================

Container(

  padding: const EdgeInsets.all(15),

  decoration: BoxDecoration(

    color: const Color(0xFFF5EFD9),

    borderRadius: BorderRadius.circular(15),

  ),

  child: const Column(

    crossAxisAlignment:
        CrossAxisAlignment.start,

    children: [

      Text(

        "Password Requirements",

        style: TextStyle(

          fontWeight: FontWeight.bold,

        ),

      ),

      SizedBox(height: 10),

      Text("• Minimum 8 characters"),

      Text("• At least 1 uppercase letter"),

      Text("• At least 1 number"),

      Text("• At least 1 special character"),

    ],

  ),

),

const SizedBox(height: 30),

// ======================
// Update Password Button
// ======================

SizedBox(

  width: double.infinity,

  height: 55,

  child: ElevatedButton(

    onPressed: () {

      if (currentPasswordController.text
          .trim()
          .isEmpty) {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              "Enter current password",
            ),

          ),

        );

        return;

      }

      if (newPasswordController.text
          .trim()
          .isEmpty) {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              "Enter new password",
            ),

          ),

        );

        return;

      }

      if (newPasswordController.text !=
          confirmPasswordController.text) {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              "Passwords do not match",
            ),

          ),

        );

        return;

      }

      if (newPasswordController.text
              .length <
          8) {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              "Password must be at least 8 characters",
            ),

          ),

        );

        return;

      }

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Password updated successfully",
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

      "Update Password",

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