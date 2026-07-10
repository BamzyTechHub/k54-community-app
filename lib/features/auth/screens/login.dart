import 'package:flutter/material.dart';
import 'package:k54_mobile/core/widgets/primary_button.dart';
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

      final AuthService authService =
    AuthService();
  bool rememberMe = false;
  bool hidePassword = true;
  bool _loggingIn = false;

  @override
void initState() {
  super.initState();

  loadRememberMe();
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  } finally {
    if (mounted) setState(() => _loggingIn = false);
  }
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
                  decoration: InputDecoration(
                    labelText: "Email",
                    hintText: "Enter Email",

                    prefixIcon: const Icon(Icons.email_outlined),

                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),

                      borderSide: const BorderSide(
                        color: Color(0xFF008000),
                        width: 2,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),

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
                  obscureText: hidePassword,

                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Enter Password",

                    prefixIcon:
                        const Icon(Icons.lock_outline),

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
                          BorderRadius.circular(16),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),

                      borderSide: const BorderSide(
                        color: Color(0xFF008000),
                        width: 2,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),

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

                    Checkbox(
                      value: rememberMe,

                      activeColor:
                          const Color(0xFF008000),

                      onChanged: (value) {
                        setState(() {
                          rememberMe = value!;
                        });
                      },
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
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 20),

                // Google Button
                 GestureDetector(
  onTap: () {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Google login will be connected later.",
      ),
    ),
  );
},

  child: _socialButton(
    "assets/images/google.png",
    "Continue with Google",
  ),
),

                const SizedBox(height: 18),

                // Facebook Button
                _socialButton(
                  "assets/images/facebook.png",
                  "Continue with Facebook",
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

  Widget _socialButton(
      String image,
      String text) {

    return Container(
      height: 55,
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFDAD7D7),
        ),
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Image.asset(
            image,
            width: 24,
          ),

          const SizedBox(width: 12),

          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}