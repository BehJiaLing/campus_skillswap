import '../../data/post_repository.dart';
import '../../models/request_post.dart';

class PostFeedViewModel {
  PostFeedViewModel(this._postRepository);

  final PostRepository _postRepository;

  Stream<List<RequestPost>> get posts => _postRepository.watchAll();
}
