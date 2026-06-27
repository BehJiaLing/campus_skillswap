import '../../data/post_repository.dart';
import '../../models/request_post.dart';

class PostFeedViewModel {
  PostFeedViewModel(PostRepository postRepository)
    : posts = postRepository.watchAll().map(
        (posts) => posts
            .where(
              (post) =>
                  post.status == RequestPostStatus.open &&
                  !post.isDeleted &&
                  !post.isBanned,
            )
            .toList(growable: false),
      );

  final Stream<List<RequestPost>> posts;
}
