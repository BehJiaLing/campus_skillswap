import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/firebase_auth_service.dart';
import '../features/posts/data/firebase_post_service.dart';
import '../features/posts/data/post_repository.dart';
import '../features/profile/data/firebase_user_profile_service.dart';
import '../features/profile/data/user_profile_repository.dart';

/// Application composition root.
///
/// Dependencies are created once here and injected into features. This keeps
/// Firebase globals out of views and makes each layer replaceable in tests.
class AppDependencies {
  AppDependencies({
    required this.authRepository,
    required this.userProfileRepository,
    required this.postRepository,
  });

  factory AppDependencies.firebase() {
    return AppDependencies(
      authRepository: AuthRepository(FirebaseAuthService()),
      userProfileRepository: UserProfileRepository(
        FirebaseUserProfileService(),
      ),
      postRepository: PostRepository(FirebasePostService()),
    );
  }

  final AuthRepository authRepository;
  final UserProfileRepository userProfileRepository;
  final PostRepository postRepository;
}
