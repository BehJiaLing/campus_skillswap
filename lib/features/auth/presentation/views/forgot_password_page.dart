import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();

  bool _loading = false;
  bool _sent = false;

  final Color navy = const Color(0xFF1A1F5E);
  final Color green = const Color(0xFF4CAF50);
  final Color bg = const Color(0xFFF5F5FA);
  final Color border = const Color(0xFFE0E0F0);
  final Color textMid = const Color(0xFF555577);

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool _isEmailValid(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      showMessage('Please enter your email.');
      return;
    }

    if (!_isEmailValid(email)) {
      showMessage('Invalid email format. Please enter a real email address.');
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      setState(() {
        _sent = true;
      });
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Failed to send reset email.');
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 13),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: navy, width: 1.5),
        ),
      ),
    );
  }

  Widget _formView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: navy,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Enter your email address and a password reset link will be sent to your email.',
          style: TextStyle(color: textMid, fontSize: 13),
        ),

        const SizedBox(height: 28),

        _label('Email'),

        const SizedBox(height: 6),

        _inputField(
          controller: _emailCtrl,
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Send Reset Link',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _successView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_read_outlined, color: green, size: 72),

          const SizedBox(height: 16),

          Text(
            'Reset Link Sent!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'A password reset link has been sent to ${_emailCtrl.text.trim()}. Please check your email, including your Spam or Junk folder.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textMid, fontSize: 13),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Back to Login',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent ? _successView() : _formView(),
      ),
    );
  }
}
