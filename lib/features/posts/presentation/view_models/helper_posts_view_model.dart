import '../../../auth/data/auth_repository.dart';
import '../../data/post_repository.dart';
import '../../models/request_post.dart';

class HelperPostsViewModel {
  HelperPostsViewModel(PostRepository repository, AuthRepository authRepository)
    : isSignedIn = authRepository.isSignedIn,
      posts = authRepository.currentUserId == null
          ? null
          : repository.watchAll().map(
              (posts) => posts
                  .where(
                    (post) =>
                        post.matchedUserId == authRepository.currentUserId &&
                        !post.isDeleted &&
                        !post.isBanned,
                  )
                  .toList(growable: false),
            );

  final bool isSignedIn;
  final Stream<List<RequestPost>>? posts;
}
