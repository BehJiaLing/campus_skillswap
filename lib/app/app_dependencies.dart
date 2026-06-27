import '../core/services/groq_matching_service.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/firebase_auth_service.dart';
import '../features/posts/data/firebase_post_service.dart';
import '../features/posts/data/post_repository.dart';
import '../features/profile/data/firebase_user_profile_service.dart';
import '../features/profile/data/user_profile_repository.dart';

class AppDependencies {
  AppDependencies({
    required this.authRepository,
    required this.userProfileRepository,
    required this.postRepository,
    required this.groqMatchingService,
  });

  factory AppDependencies.firebase() {
    return AppDependencies(
      authRepository: AuthRepository(FirebaseAuthService()),
      userProfileRepository: UserProfileRepository(
        FirebaseUserProfileService(),
      ),
      postRepository: PostRepository(FirebasePostService()),
      groqMatchingService: GroqMatchingService(),
    );
  }

  final AuthRepository authRepository;
  final UserProfileRepository userProfileRepository;
  final PostRepository postRepository;
  final GroqMatchingService groqMatchingService;
}
