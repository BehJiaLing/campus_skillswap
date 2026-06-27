import '../models/session_user.dart';
import 'firebase_auth_service.dart';

/// Source of truth for the active application session.
class AuthRepository {
  AuthRepository(this._service);

  final FirebaseAuthService _service;

  String? get currentUserId => _service.currentUser?.uid;

  String? get currentUserEmail => _service.currentUser?.email;

  bool get isSignedIn => _service.currentUser != null;

  SessionUser? get currentUser {
    final user = _service.currentUser;
    if (user == null) return null;
    return SessionUser(
      id: user.uid,
      email: user.email,
      emailVerified: user.emailVerified,
    );
  }

  Future<SessionUser?> signIn(String email, String password) async {
    return _service.signIn(email, password);
  }

  Future<SessionUser?> register(String email, String password) async {
    return _service.register(email, password);
  }

  Future<SessionUser?> reloadCurrentUser() async {
    return _service.reloadCurrentUser();
  }

  Future<void> sendVerificationEmail() => _service.sendVerificationEmail();

  Future<void> sendPasswordResetEmail(String email) =>
      _service.sendPasswordResetEmail(email);

  Future<void> signOut() => _service.signOut();
}
