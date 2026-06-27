import '../../../profile/data/user_profile_repository.dart';
import '../../data/auth_repository.dart';

class StartupViewModel {
  StartupViewModel(this._authRepository, this._profileRepository);

  final AuthRepository _authRepository;
  final UserProfileRepository _profileRepository;

  Future<String> resolveStartRoute() async {
    var user = _authRepository.currentUser;
    if (user == null) return '/login';

    try {
      user = await _authRepository.reloadCurrentUser();
      if (user == null) return '/login';
      if (!user.emailVerified) return '/verify-email';

      final profile = await _profileRepository.getProfile(user.id);
      if (profile == null) return '/create-profile';

      if (profile.suspended || profile.banned) {
        await _authRepository.signOut();
        return '/login';
      }

      await _profileRepository.setOnline(user.id, true);

      if (profile.role.isAdmin) return '/admin/dashboard';
      if (!profile.profileCompleted) return '/create-profile';
      return '/post';
    } catch (_) {
      return '/login';
    }
  }
}
