import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isChecking = false;
  bool isResending = false;

  final Color navy = const Color(0xFF1A1F5E);
  final Color green = const Color(0xFF4CAF50);
  final Color textMid = const Color(0xFF555577);

  Future<void> checkEmailVerified() async {
    setState(() {
      isChecking = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await user.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'emailVerified': true});

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/create-profile');
      } else {
        showMessage(
          'Email not verified yet. Please check your inbox or spam folder.',
        );
      }
    } catch (e) {
      showMessage('Failed to check verification. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isChecking = false;
        });
      }
    }
  }

  Future<void> resendVerificationEmail() async {
    setState(() {
      isResending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await user.sendEmailVerification();

      showMessage(
        'Verification email sent again. Please check your inbox or spam folder.',
      );
    } catch (e) {
      showMessage('Failed to resend email. Please try again later.');
    } finally {
      if (mounted) {
        setState(() {
          isResending = false;
        });
      }
    }
  }

  Future<void> backToLogin() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/login');
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'your email';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_unread_outlined, size: 90, color: navy),

            const SizedBox(height: 24),

            Text(
              'Verify Your Email',
              style: TextStyle(
                color: navy,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'A verification email has been sent to:',
              style: TextStyle(color: textMid, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            Text(
              userEmail,
              style: TextStyle(
                color: navy,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 14),

            Text(
              'Please open your email, click the verification link, then come back and press the button below.',
              style: TextStyle(color: textMid, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isChecking ? null : checkEmailVerified,
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                ),
                child: isChecking
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'I Have Verified',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: isResending ? null : resendVerificationEmail,
                style: OutlinedButton.styleFrom(
                  foregroundColor: navy,
                  side: BorderSide(color: navy),
                ),
                child: isResending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Resend Verification Email',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: backToLogin,
              child: Text('Back to Login', style: TextStyle(color: navy)),
            ),
          ],
        ),
      ),
    );
  }
}
