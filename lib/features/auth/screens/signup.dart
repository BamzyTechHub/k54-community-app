import 'package:flutter/material.dart';
import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/core/widgets/social_button.dart';
import 'package:k54_mobile/features/auth/screens/login.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
final AuthService authService = AuthService();
  // Controllers
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmController =
      TextEditingController();


  // Focus Nodes
  final FocusNode nameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmFocus = FocusNode();


  // States
  bool agree = false;

  bool showPassword = false;

  bool showConfirmPassword = false;
  bool _signingUp = false;

  Future<void> _submit() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _signingUp = true);
    try {
      final fullName = nameController.text.trim();
      final parts = fullName.split(" ");

      final firstName = parts.first;
      final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

      final username = emailController.text.trim().split("@").first;

      await authService.register(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        firstName: firstName,
        lastName: lastName,
        username: username,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Registration successful! Please check your email to activate your account.",
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _signingUp = false);
    }
  }


  @override
  void initState() {
    super.initState();
    // Drives the gray fill-on-focus look confirmed against the Sign Up
    // Figma frames - each focus node already existed for something else
    // (or was unused), but nothing was rebuilding on focus change, so the
    // fields never visually reacted to focus at all.
    for (final node in [nameFocus, emailFocus, passwordFocus, confirmFocus]) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();

    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmFocus.dispose();

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
              horizontal: 25,
            ),

            child: Column(

              children: [

                const SizedBox(height: 25),


                // Logo
                Image.asset(
                  "assets/images/k54_logo.png",
                  width: 120,
                ),


                const SizedBox(height: 25),


                const Text(
                  "Sign Up",

                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),


                const SizedBox(height: 5),


                const Text(
                  "Input your details below to proceed",

                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),


                const SizedBox(height: 25),
                // Full Name
_buildTextField(
  controller: nameController,
  focusNode: nameFocus,
  hint: "Full Name",
  icon: Icons.person_outline,
),

const SizedBox(height: 15),

// Email
_buildTextField(
  controller: emailController,
  focusNode: emailFocus,
  hint: "Enter Email",
  icon: Icons.email_outlined,
),

const SizedBox(height: 15),

// Password
_buildPasswordField(
  controller: passwordController,
  focusNode: passwordFocus,
  hint: "Enter Password",
  visible: showPassword,
  onTap: () {
    setState(() {
      showPassword = !showPassword;
    });
  },
),

const SizedBox(height: 15),

// Confirm Password
_buildPasswordField(
  controller: confirmController,
  focusNode: confirmFocus,
  hint: "Confirm Password",
  visible: showConfirmPassword,
  onTap: () {
    setState(() {
      showConfirmPassword = !showConfirmPassword;
    });
  },
),

const SizedBox(height: 20),


// Checkbox
Row(
  children: [

    GestureDetector(
      onTap: () => setState(() => agree = !agree),
      child: Container(
        width: 26,
        height: 26,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: agree ? const Color(0xFF008000) : Colors.transparent,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(5),
        ),
        child: agree
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    ),

    const Expanded(

      child: Text(
        "I agree to the terms and conditions",

        style: TextStyle(
          fontSize: 13,
        ),

      ),

    ),

  ],

),


const SizedBox(height: 25),


// Sign Up Button
PrimaryButton(
  label: "Sign Up",
  loading: _signingUp,
  onPressed: agree ? _submit : null,
),


const SizedBox(height: 20),


const Text(

  "Or",

  style: TextStyle(

    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.jetBlack,

  ),

),
const SizedBox(height: 20),

SocialButton(
  iconAsset: "assets/images/google.png",
  label: "Continue with Google",
  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Google login will be connected later.")),
    );
  },
),

const SizedBox(height: 15),

SocialButton(
  iconAsset: "assets/images/facebook.png",
  label: "Continue with Facebook",
  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Facebook login will be connected later.")),
    );
  },
),

const SizedBox(height: 30),

Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [

    const Text(
      "Already Have an account? ",
      style: TextStyle(
        fontSize: 16,
        color: Colors.black,
      ),
    ),


   GestureDetector(
  onTap: () {
    // Reached from Login it can just pop back - but reached from
    // Onboarding4 (which clears the stack via pushAndRemoveUntil) there
    // is nothing to pop to, and an unconditional pop() was a silent
    // no-op there. Found via a code-level trace of every entry path into
    // this screen, not runtime testing.
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  },

  child: const Text(
    "Log In",
    style: TextStyle(
      color: Color(0xFF008000),
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
),

  ],
),

const SizedBox(height: 20),

              ],
            ),
          ),
        ),
      ),
    );
  }


Widget _buildTextField({
  required TextEditingController controller,
  required FocusNode focusNode,
  required String hint,
  required IconData icon,
}) {

  return TextField(
    controller: controller,
    focusNode: focusNode,

    decoration: InputDecoration(
      prefixIcon: Icon(icon),

      hintText: hint,

      // Gray fill only while focused - confirmed against the Sign Up
      // Figma frames the same way as Login's.
      filled: focusNode.hasFocus,
      fillColor: const Color(0xFFFCF8ED),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF008000),
          width: 2,
        ),
      ),
    ),
  );
}


Widget _buildPasswordField({
  required TextEditingController controller,
  required FocusNode focusNode,
  required String hint,
  required bool visible,
  required VoidCallback onTap,
}) {

  return TextField(
    controller: controller,
    focusNode: focusNode,
    obscureText: !visible,

    decoration: InputDecoration(

      prefixIcon: const Icon(
        Icons.lock_outline,
      ),

      suffixIcon: GestureDetector(
        onTap: onTap,

        child: Icon(
          visible
              ? Icons.visibility
              : Icons.visibility_off,
        ),
      ),

      hintText: hint,

      filled: focusNode.hasFocus,
      fillColor: const Color(0xFFFCF8ED),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF008000),
          width: 2,
        ),
      ),
    ),
  );
}


}