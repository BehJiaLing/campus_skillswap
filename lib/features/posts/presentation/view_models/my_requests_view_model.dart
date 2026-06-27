import '../../../auth/data/auth_repository.dart';
import '../../data/post_repository.dart';
import '../../models/request_post.dart';

class MyRequestsViewModel {
  MyRequestsViewModel(PostRepository postRepository, this._authRepository)
    : posts = _createPostsStream(postRepository, _authRepository);

  final AuthRepository _authRepository;
  final Stream<List<RequestPost>>? posts;

  bool get isSignedIn => _authRepository.isSignedIn;

  static Stream<List<RequestPost>>? _createPostsStream(
    PostRepository repository,
    AuthRepository authRepository,
  ) {
    final userId = authRepository.currentUserId;
    return userId == null ? null : repository.watchByOwner(userId);
  }
}
