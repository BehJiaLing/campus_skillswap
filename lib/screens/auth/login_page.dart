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

  final Color cardBlue = const Color(0xFFC8D4F0);
  final Color navColor = const Color(0xFFD7E3E4);
  final Color darkText = const Color(0xFF1F223D);
  final Color greenButton = const Color(0xFFB8F2B8);

  Future<void> login() async {
    if (emailCtrl.text.trim().isEmpty || passwordCtrl.text.trim().isEmpty) {
      showMessage("Please enter email and password");
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      final uid = credential.user?.uid;

      if (uid == null) {
        showMessage("User not found");
        return;
      }

      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        showMessage("User profile not found in database");
        return;
      }

      final data = userDoc.data() ?? {};
      final role = data['role'] ?? 'user';

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/adminDashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/post');
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? "Login failed");
    } catch (e) {
      showMessage("Error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> resetPassword() async {
    if (emailCtrl.text.trim().isEmpty) {
      showMessage("Please enter your email first");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailCtrl.text.trim(),
      );
      showMessage("Password reset email sent");
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? "Reset password failed");
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),

              Center(
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: cardBlue,
                  child: Icon(
                    Icons.school_rounded,
                    size: 60,
                    color: darkText,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              Text(
                "Welcome back.",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Login to Campus SkillSwap",
                style: TextStyle(
                  fontSize: 20,
                  color: darkText.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 35),

              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  filled: true,
                  fillColor: navColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: passwordCtrl,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  filled: true,
                  fillColor: navColor,
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => hidePassword = !hidePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: resetPassword,
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(color: darkText),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenButton,
                    foregroundColor: darkText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(
                    "Don't have an account? Register",
                    style: TextStyle(color: darkText),
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