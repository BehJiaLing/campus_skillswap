import '../../../auth/data/auth_repository.dart';
import '../../data/post_repository.dart';
import '../../models/request_post.dart';

class MyRequestsViewModel {
  MyRequestsViewModel(this._postRepository, this._authRepository);

  final PostRepository _postRepository;
  final AuthRepository _authRepository;

  bool get isSignedIn => _authRepository.isSignedIn;

  Stream<List<RequestPost>>? get posts {
    final userId = _authRepository.currentUserId;
    return userId == null ? null : _postRepository.watchByOwner(userId);
  }
}
