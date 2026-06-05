import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  String? loginError;

  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);
  final Color textMid = const Color(0xFF555577);
  final Color textLight = const Color(0xFF9999BB);
  final Color border = const Color(0xFFE0E0F0);
  final Color green = const Color(0xFF4CAF50);

  Future<void> login() async {
    setState(() {
      loginError = null;
    });

    if (emailCtrl.text.trim().isEmpty || passwordCtrl.text.trim().isEmpty) {
      setState(() {
        loginError = "Please enter email and password.";
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      final user = credential.user;

      if (user == null) {
        setState(() {
          loginError = "User not found.";
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          loginError = "User profile not found.";
        });
        await FirebaseAuth.instance.signOut();
        return;
      }

      final data = userDoc.data() ?? {};
      final role = data['role'] ?? 'user';
      final profileCompleted = data['profileCompleted'] ?? false;
      final suspended = data['suspended'] ?? false;

      if (suspended == true) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          loginError = "Your account has been suspended.";
        });
        return;
      }

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      } else if (profileCompleted == false) {
        Navigator.pushReplacementNamed(context, '/create-profile');
      } else {
        Navigator.pushReplacementNamed(context, '/post');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'invalid-credential') {
          loginError = "Incorrect email or password.";
        } else if (e.code == 'user-not-found') {
          loginError = "No account found with this email.";
        } else if (e.code == 'wrong-password') {
          loginError = "Wrong password. Please try again.";
        } else if (e.code == 'invalid-email') {
          loginError = "Invalid email format.";
        } else {
          loginError = e.message ?? "Login failed.";
        }
      });
    } catch (e) {
      setState(() {
        loginError = "Error: $e";
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> resetPassword() async {
    setState(() {
      loginError = null;
    });

    if (emailCtrl.text.trim().isEmpty) {
      setState(() {
        loginError = "Please enter your email first.";
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailCtrl.text.trim(),
      );

      setState(() {
        loginError = "Password reset email sent. Please check your inbox.";
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        loginError = e.message ?? "Reset password failed.";
      });
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
        color: bg,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: textLight, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _errorBox() {
    if (loginError == null) return const SizedBox.shrink();

    final isSuccess = loginError!.toLowerCase().contains('sent');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? green : Colors.redAccent,
        ),
      ),
      child: Text(
        loginError!,
        style: TextStyle(
          color: isSuccess ? green : Colors.redAccent,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 36),
              ),

              const SizedBox(height: 24),

              Text(
                'Welcome to\nCampus SkillSwap',
                style: TextStyle(
                  color: navy,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Exchange skills, request help, chat with others, and track your learning progress.',
                style: TextStyle(color: textMid, fontSize: 14, height: 1.6),
              ),

              const SizedBox(height: 40),

              _inputField(
                controller: emailCtrl,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 10),

              _inputField(
                controller: passwordCtrl,
                hintText: 'Password',
                obscureText: hidePassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: textLight,
                  ),
                ),
              ),

              _errorBox(),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgot-password'),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(fontSize: 12, color: navy),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Login',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: navy,
                    side: BorderSide(color: navy),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    'Register New Student Account',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}