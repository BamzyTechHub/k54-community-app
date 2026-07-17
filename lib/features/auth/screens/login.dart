import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:k54_mobile/core/theme/app_colors.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
import 'package:k54_mobile/core/widgets/social_button.dart';
import 'package:k54_mobile/features/auth/screens/touch_id.dart';
import 'package:k54_mobile/features/auth/screens/forgot_password.dart';
import 'package:k54_mobile/features/auth/screens/signup.dart';
import 'package:k54_mobile/features/auth/screens/face_id.dart';
import 'package:k54_mobile/features/home/screens/home_page.dart';
import 'package:k54_mobile/core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}
class _LoginState extends State<Login> {

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  // Drive the gray fill-on-focus look confirmed against the Log In
  // Figma frames (both variants show the actively-focused field with a
  // light gray background in addition to the green border) - plain
  // InputDecoration has no built-in "fill only while focused" behavior,
  // so this needs an explicit FocusNode + listener to rebuild.
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

      final AuthService authService =
    AuthService();
  bool rememberMe = false;
  bool hidePassword = true;
  bool _loggingIn = false;

  @override
void initState() {
  super.initState();

  loadRememberMe();
  emailFocus.addListener(() => setState(() {}));
  passwordFocus.addListener(() => setState(() {}));
}

@override
void dispose() {
  emailController.dispose();
  passwordController.dispose();
  emailFocus.dispose();
  passwordFocus.dispose();
  super.dispose();
}

Future<void> loadRememberMe() async {

  final prefs = await SharedPreferences.getInstance();

  rememberMe = prefs.getBool("rememberMe") ?? false;

  if (rememberMe) {

    emailController.text =
        prefs.getString("email") ?? "";

  }

  setState(() {});
}

Future<void> _login() async {
  if (emailController.text.isEmpty || passwordController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter your email and password")),
    );
    return;
  }

  setState(() => _loggingIn = true);
  try {
    final success = await authService.login(
      username: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (success) {
      final response = await authService.getCurrentUser();
      debugPrint(response.data.toString());

      final prefs = await SharedPreferences.getInstance();

      if (rememberMe) {
        await prefs.setBool("rememberMe", true);
        await prefs.setString("email", emailController.text.trim());
      } else {
        await prefs.remove("rememberMe");
        await prefs.remove("email");
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_describeLoginError(e)),
        duration: const Duration(seconds: 10),
      ),
    );
  } finally {
    if (mounted) setState(() => _loggingIn = false);
  }
}

// Turns a DioException into a message a non-technical tester can
// screenshot and send back, that still tells us exactly which stage
// failed - added 2026-07-16 to diagnose a release-build "login times
// out after 30s" report from a remote tester with no adb/log access.
String _describeLoginError(Object e) {
  if (e is DioException) {
    final stage = switch (e.type) {
      DioExceptionType.connectionTimeout => "couldn't connect to the server (connect timeout)",
      DioExceptionType.sendTimeout => "timed out sending the request",
      DioExceptionType.receiveTimeout => "connected, but got no response back (receive timeout)",
      DioExceptionType.connectionError => "connection error (${e.error})",
      DioExceptionType.badResponse => "server responded with ${e.response?.statusCode}",
      DioExceptionType.badCertificate => "SSL certificate error",
      DioExceptionType.cancel => "request was cancelled",
      _ => "unknown error (${e.message})",
    };
    return "Login failed: $stage";
  }
  return "Login failed: $e";
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),

            child: Column(
              children: [

                const SizedBox(height: 20),

                // Logo
                Image.asset(
                  "assets/images/k54_logo.png",
                  width: 140,
                ),

                const SizedBox(height: 25),

                // Welcome Text
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  "Let's get you back in.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF505050),
                  ),
                ),

                const SizedBox(height: 30),

                // Email Field
                TextField(
  controller: emailController,
  focusNode: emailFocus,
                  decoration: InputDecoration(
                    labelText: "Email",
                    hintText: "Enter Email",

                    prefixIcon: const Icon(Icons.email_outlined),

                    // Gray fill only while focused - confirmed against
                    // both Log In Figma frames, which show the active
                    // field with a light gray background on top of the
                    // green border, not just the border alone.
                    filled: emailFocus.hasFocus,
                    fillColor: const Color(0xFFFCF8ED),

                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),

                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),

                      borderSide: const BorderSide(
                        color: Color(0xFF008000),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),



                // Password Field
                TextField(
  controller: passwordController,
  focusNode: passwordFocus,
                  obscureText: hidePassword,

                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Enter Password",

                    prefixIcon:
                        const Icon(Icons.lock_outline),

                    filled: passwordFocus.hasFocus,
                    fillColor: const Color(0xFFFCF8ED),

                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),

                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),

                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),

                      borderSide: const BorderSide(
                        color: Color(0xFF008000),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Align(
  alignment: Alignment.centerRight,
  child: GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ForgotPassword(),
        ),
      );
    },
    child: const Text(
      "Forgot Password?",
      style: TextStyle(
        color: Color(0xFF008000),
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),

const SizedBox(height: 10),

                // Remember Me
                Row(
                  children: [

                    GestureDetector(
                      onTap: () => setState(() => rememberMe = !rememberMe),
                      child: Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: rememberMe ? const Color(0xFF008000) : Colors.transparent,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: rememberMe
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    ),

                    const Text(
                      "Remember me",
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Login Button
                PrimaryButton(
                  label: "Login",
                  loading: _loggingIn,
                  onPressed: _login,
                ),

                const SizedBox(height: 30),

                // Biometric Icons
Row(
  mainAxisAlignment: MainAxisAlignment.center,

  children: [

    // Fingerprint
    GestureDetector(
      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TouchId(),
          ),
        );

      },

      child: Image.asset(
        "assets/images/fingerprint.png",
        width: 60,
      ),
    ),


    const SizedBox(width: 40),


    // Face ID
    GestureDetector(
      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FaceId(),
          ),
        );

      },

      child: Image.asset(
        "assets/images/face_id.png",
        width: 60,
      ),
    ),

  ],
),
                // Sign Up Button
                PrimaryButton(
                  label: "Sign Up",
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUp()),
                  ),
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

                // Google Button
                SocialButton(
                  iconAsset: "assets/images/google.png",
                  label: "Continue with Google",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Google login will be connected later.")),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // Facebook Button
                SocialButton(
                  iconAsset: "assets/images/facebook.png",
                  label: "Continue with Facebook",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Facebook login will be connected later.")),
                    );
                  },
                ),

                const SizedBox(height: 25),

                // Bottom Text
                Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Text(
      "Don't have an account? ",
    ),

    GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SignUp(),
          ),
        );
      },

      child: const Text(
        "Sign Up",
        style: TextStyle(
          color: Color(0xFF008000),
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ],
),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}