import 'package:flutter/foundation.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../profile/data/user_profile_repository.dart';
import '../../data/post_repository.dart';
import '../../models/request_interactions.dart';
import '../../models/request_post.dart';

class RequestPostDetailViewModel extends ChangeNotifier {
  RequestPostDetailViewModel(
    this._postRepository,
    this._authRepository,
    this._profileRepository,
    this.postId,
  );

  final PostRepository _postRepository;
  final AuthRepository _authRepository;
  final UserProfileRepository _profileRepository;
  final String postId;

  bool _busy = false;
  String? _errorMessage;

  bool get busy => _busy;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _authRepository.currentUserId;
  Stream<RequestPost?> get post => _postRepository.watchOne(postId);
  Stream<List<HelpOffer>> get offers => _postRepository.watchOffers(postId);
  Stream<List<RequestComment>> get comments =>
      _postRepository.watchComments(postId);
  Stream<List<RequestRating>> get ratings =>
      _postRepository.watchRatings(postId);

  bool isOwner(RequestPost post) => post.userId == currentUserId;

  bool canOffer(RequestPost post) =>
      currentUserId != null &&
      !isOwner(post) &&
      post.status == RequestPostStatus.open;

  Future<bool> offerHelp(RequestPost post) async {
    final userId = currentUserId;
    if (userId == null) return _fail('Please sign in again.');
    final profile = await _profileRepository.getProfile(userId);
    if (profile == null) {
      return _fail('Complete your profile before offering help.');
    }

    final score = SkillMatchScorer.score(
      requestedSkill: post.skillNeeded,
      requesterCourse: post.course,
      helperSkills: profile.skills,
      helperCourse: profile.course,
    );

    return _run(
      () => _postRepository.offerHelp(postId, {
        'userId': userId,
        'userName': profile.name,
        'course': profile.course,
        'skills': profile.skills,
        'matchScore': score,
      }),
    );
  }

  Future<bool> addComment(String message) async {
    final userId = currentUserId;
    final cleanMessage = message.trim();
    if (userId == null) return _fail('Please sign in again.');
    if (cleanMessage.isEmpty) return _fail('Write a comment first.');
    final profile = await _profileRepository.getProfile(userId);
    return _run(
      () => _postRepository.addComment(postId, {
        'userId': userId,
        'userName':
            profile?.name ?? _authRepository.currentUserEmail ?? 'Student',
        'message': cleanMessage,
      }),
    );
  }

  Future<bool> acceptOffer(RequestPost post, HelpOffer offer) {
    if (!isOwner(post)) {
      return Future.value(_fail('Only the request owner can choose a helper.'));
    }
    return _run(() async {
      await _postRepository.acceptOffer(
        postId: postId,
        ownerId: post.userId,
        helperId: offer.userId,
        helperName: offer.userName,
      );
    });
  }

  Future<bool> advanceStatus(RequestPost post) {
    if (!isOwner(post)) {
      return Future.value(_fail('Only the request owner can update status.'));
    }
    final next = switch (post.status) {
      RequestPostStatus.matched => RequestPostStatus.inProgress,
      RequestPostStatus.inProgress => RequestPostStatus.completed,
      _ => null,
    };
    if (next == null) {
      return Future.value(_fail('This request cannot advance yet.'));
    }
    return _run(() => _postRepository.updateStatus(postId, next));
  }

  Future<bool> submitRating(RequestPost post, int stars, String review) {
    final userId = currentUserId;
    if (userId == null) return Future.value(_fail('Please sign in again.'));
    if (post.status != RequestPostStatus.completed) {
      return Future.value(_fail('Complete the request before rating.'));
    }
    final targetId = isOwner(post) ? post.matchedUserId : post.userId;
    if (targetId == null ||
        (userId != post.userId && userId != post.matchedUserId)) {
      return Future.value(
        _fail('Only matched participants can submit a rating.'),
      );
    }
    return _run(
      () => _postRepository.addRating(postId, {
        'fromUserId': userId,
        'toUserId': targetId,
        'stars': stars.clamp(1, 5),
        'review': review.trim(),
      }),
    );
  }

  bool _fail(String message) {
    _errorMessage = message;
    notifyListeners();
    return false;
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to complete that action. Please try again.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
