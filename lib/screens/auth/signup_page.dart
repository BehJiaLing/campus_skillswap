import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _rePassCtrl = TextEditingController();

  Timer? _emailDebounce;

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  bool _checkingEmail = false;

  String? _emailError;

  final Color navy = const Color(0xFF1A1F5E);
  final Color green = const Color(0xFF4CAF50);
  final Color bg = const Color(0xFFF5F5FA);
  final Color textMid = const Color(0xFF555577);
  final Color textLight = const Color(0xFF9999BB);
  final Color border = const Color(0xFFE0E0F0);

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_checkEmailLive);
    _passCtrl.addListener(_checkPasswordStrength);
  }

  bool _isEmailValid(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void _checkEmailLive() {
    final email = _emailCtrl.text.trim().toLowerCase();

    _emailDebounce?.cancel();

    if (email.isEmpty) {
      setState(() {
        _emailError = null;
        _checkingEmail = false;
      });
      return;
    }

    if (!_isEmailValid(email)) {
      setState(() {
        _emailError = 'Invalid email format. Example: name@gmail.com';
        _checkingEmail = false;
      });
      return;
    }

    setState(() {
      _emailError = null;
      _checkingEmail = true;
    });

    _emailDebounce = Timer(const Duration(milliseconds: 700), () {
      _checkEmailAlreadyRegistered(email);
    });
  }

  Future<bool> _checkEmailAlreadyRegistered(String email) async {
    final currentEmail = email.trim().toLowerCase();

    if (currentEmail.isEmpty || !_isEmailValid(currentEmail)) {
      return false;
    }

    try {
      final registeredEmailDoc = await FirebaseFirestore.instance
          .collection('registered_emails')
          .doc(currentEmail)
          .get();

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: currentEmail)
          .limit(1)
          .get();

      final alreadyRegistered =
          registeredEmailDoc.exists || userQuery.docs.isNotEmpty;

      if (!mounted) return alreadyRegistered;

      final latestTypedEmail = _emailCtrl.text.trim().toLowerCase();

      if (latestTypedEmail != currentEmail) {
        return alreadyRegistered;
      }

      setState(() {
        _checkingEmail = false;
        _emailError = alreadyRegistered
            ? 'This email is already registered. Please login instead.'
            : null;
      });

      return alreadyRegistered;
    } catch (e) {
      if (!mounted) return false;

      setState(() {
        _checkingEmail = false;
      });

      return false;
    }
  }

  void _checkPasswordStrength() {
    final password = _passCtrl.text;

    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      _hasSpecial =
          RegExp(r'[!@#\$&*~%^()_\-+=\[{\]};:<>|./?]').hasMatch(password);
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength &&
          _hasUppercase &&
          _hasLowercase &&
          _hasNumber &&
          _hasSpecial;

  Future<void> _signup() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passCtrl.text.trim();
    final rePassword = _rePassCtrl.text.trim();

    if (email.isEmpty || password.isEmpty || rePassword.isEmpty) {
      showMessage('Please fill in all fields.');
      return;
    }

    if (!_isEmailValid(email)) {
      setState(() {
        _emailError = 'Invalid email format. Example: name@gmail.com';
      });
      return;
    }

    if (!_isPasswordValid) {
      showMessage(
        'Password must have at least 8 characters, uppercase, lowercase, number, and symbol.',
      );
      return;
    }

    if (password != rePassword) {
      showMessage('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);

    try {
      final alreadyRegistered = await _checkEmailAlreadyRegistered(email);

      if (alreadyRegistered) {
        showMessage('This email is already registered. Please login instead.');
        return;
      }

      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        showMessage('User not created.');
        return;
      }

      await user.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'role': 'user',
        'profileCompleted': false,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('registered_emails')
          .doc(email)
          .set({
        'email': email,
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      showMessage(
        'Account created. Please verify your email before logging in.',
      );

      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() {
          _emailError =
          'This email is already registered. Please login instead.';
        });
        showMessage('This email is already registered. Please login instead.');
      } else if (e.code == 'weak-password') {
        showMessage('Password is too weak.');
      } else if (e.code == 'invalid-email') {
        setState(() {
          _emailError = 'Invalid email format. Example: name@gmail.com';
        });
      } else {
        showMessage(e.message ?? 'Sign up failed.');
      }
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _checkingEmail = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailDebounce?.cancel();
    _emailCtrl.removeListener(_checkEmailLive);
    _passCtrl.removeListener(_checkPasswordStrength);
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _rePassCtrl.dispose();
    super.dispose();
  }

  Widget _ruleItem(String text, bool valid) {
    return Row(
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.cancel_outlined,
          size: 18,
          color: valid ? Colors.green : Colors.redAccent,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: valid ? Colors.green : textMid,
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        filled: true,
        fillColor: bg,
        suffixIcon: suffixIcon,
        hintStyle: TextStyle(color: textLight, fontSize: 13),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: navy,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }

  Widget? _emailSuffixIcon() {
    final email = _emailCtrl.text.trim().toLowerCase();

    if (_checkingEmail) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (email.isNotEmpty && _emailError == null && _isEmailValid(email)) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 20,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Email'),
            const SizedBox(height: 6),
            _inputField(
              controller: _emailCtrl,
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
              suffixIcon: _emailSuffixIcon(),
            ),

            const SizedBox(height: 14),

            _label('Password'),
            const SizedBox(height: 6),
            _inputField(
              controller: _passCtrl,
              hintText: 'Create password',
              obscureText: _obscure1,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure1 ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: textLight,
                ),
                onPressed: () => setState(() => _obscure1 = !_obscure1),
              ),
            ),

            const SizedBox(height: 10),

            _ruleItem('At least 8 characters', _hasMinLength),
            const SizedBox(height: 6),
            _ruleItem('At least 1 uppercase letter', _hasUppercase),
            const SizedBox(height: 6),
            _ruleItem('At least 1 lowercase letter', _hasLowercase),
            const SizedBox(height: 6),
            _ruleItem('At least 1 number', _hasNumber),
            const SizedBox(height: 6),
            _ruleItem('At least 1 symbol', _hasSpecial),

            const SizedBox(height: 14),

            _label('Re-type Password'),
            const SizedBox(height: 6),
            _inputField(
              controller: _rePassCtrl,
              hintText: 'Re-enter password',
              obscureText: _obscure2,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure2 ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: textLight,
                ),
                onPressed: () => setState(() => _obscure2 = !_obscure2),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                ),
                child: _loading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Create',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(color: navy),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}