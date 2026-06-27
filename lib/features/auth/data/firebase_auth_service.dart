import 'package:firebase_auth/firebase_auth.dart';

import '../models/session_user.dart';

/// Lowest-level Firebase Authentication adapter.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<SessionUser?> signIn(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _map(credential.user);
  }

  Future<SessionUser?> register(String email, String password) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _map(credential.user);
  }

  Future<SessionUser?> reloadCurrentUser() async {
    await _firebaseAuth.currentUser?.reload();
    return _map(_firebaseAuth.currentUser);
  }

  Future<void> sendVerificationEmail() async {
    await _firebaseAuth.currentUser?.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  SessionUser? _map(User? user) {
    if (user == null) return null;
    return SessionUser(
      id: user.uid,
      email: user.email,
      emailVerified: user.emailVerified,
    );
  }
}
