import 'package:flutter/foundation.dart';

import '../../../../core/services/groq_matching_service.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../profile/data/user_profile_repository.dart';
import '../../../profile/models/user_profile.dart';
import '../../data/post_repository.dart';
import '../../models/ai_match.dart';
import '../../models/request_interactions.dart';
import '../../models/request_post.dart';

class RequestPostDetailViewModel extends ChangeNotifier {
  RequestPostDetailViewModel(
    PostRepository postRepository,
    this._authRepository,
    this._profileRepository,
    this._groqMatchingService,
    this.postId,
  ) : _postRepository = postRepository {
    post = postRepository.watchOne(postId);
    offers = postRepository.watchOffers(postId);
    aiMatches = postRepository.watchAiMatches(postId);
    comments = postRepository.watchComments(postId);
    ratings = postRepository.watchRatings(postId);
  }

  final PostRepository _postRepository;
  final AuthRepository _authRepository;
  final UserProfileRepository _profileRepository;
  final GroqMatchingService _groqMatchingService;
  final String postId;

  bool _busy = false;
  bool _commentBusy = false;
  String? _errorMessage;
  List<AiMatch> _rankedOffers = const [];

  bool get busy => _busy;
  bool get commentBusy => _commentBusy;
  String? get errorMessage => _errorMessage;
  List<AiMatch> get rankedOffers => _rankedOffers;
  String? get currentUserId => _authRepository.currentUserId;

  late final Stream<RequestPost?> post;
  late final Stream<List<HelpOffer>> offers;
  late final Stream<List<AiMatch>> aiMatches;
  late final Stream<List<RequestComment>> comments;
  late final Stream<List<RequestRating>> ratings;

  bool isOwner(RequestPost post) => post.userId == currentUserId;

  bool canOffer(RequestPost post) =>
      currentUserId != null &&
      !isOwner(post) &&
      post.pendingHelperId == null &&
      post.status == RequestPostStatus.open;

  Future<UserProfile?> getHelperProfile(String userId) =>
      _profileRepository.getProfile(userId);

  Future<bool> generateAiMatches(RequestPost post) async {
    if (!isOwner(post)) {
      return _fail('Only the request owner can generate AI matches.');
    }

    return _run(() async {
      final users = await _profileRepository.getAllProfiles();

      final groqMatches = await _groqMatchingService.matchProfiles(
        post: post,
        users: users,
      );

      final matches = groqMatches.map((match) {
        return AiMatch(
          userId: match.userId,
          userName: match.userName,
          course: match.course,
          skills: match.skills,
          matchPercentage: match.matchPercentage,
          reason: match.reason,
        );
      }).toList();

      await _postRepository.saveAiMatches(postId, matches);
    });
  }

  Future<bool> rankHelperOffers(
    RequestPost post,
    List<HelpOffer> offers,
  ) async {
    if (!isOwner(post)) {
      return _fail('Only the request owner can rank helper offers.');
    }
    if (offers.length < 2) {
      return _fail('At least two helper offers are needed for AI ranking.');
    }

    return _run(() async {
      final ranked = await _groqMatchingService.rankOffers(
        post: post,
        offers: offers,
      );
      _rankedOffers = ranked
          .map(
            (match) => AiMatch(
              userId: match.userId,
              userName: match.userName,
              course: match.course,
              skills: match.skills,
              matchPercentage: match.matchPercentage,
              reason: match.reason,
            ),
          )
          .toList(growable: false);
    });
  }

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
        'campus': profile.campus,
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
    _commentBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _postRepository.addComment(postId, {
        'userId': userId,
        'userName':
            profile?.name ?? _authRepository.currentUserEmail ?? 'Student',
        'message': cleanMessage,
      });
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _commentBusy = false;
      notifyListeners();
    }
  }

  Future<bool> updatePost(RequestPost post, UpdateRequestPostInput input) {
    if (!isOwner(post)) {
      return Future.value(_fail('Only the owner can edit this post.'));
    }
    if (input.title.trim().isEmpty ||
        input.skillNeeded.trim().isEmpty ||
        input.description.trim().isEmpty) {
      return Future.value(
        _fail('Post name, skill and description are required.'),
      );
    }
    return _run(() => _postRepository.updatePost(postId, input));
  }

  Future<bool> deletePost(RequestPost post) {
    if (!isOwner(post)) {
      return Future.value(_fail('Only the owner can delete this post.'));
    }
    return _run(() => _postRepository.softDeletePost(postId, post.userId));
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

  Future<bool> submitRating(RequestPost post, int stars, String review) {
    final userId = currentUserId;
    if (userId == null) return Future.value(_fail('Please sign in again.'));
    if (!isOwner(post) || post.status != RequestPostStatus.matched) {
      return Future.value(
        _fail('Only the requester can end and rate this match.'),
      );
    }
    final targetId = post.matchedUserId;
    if (targetId == null || userId != post.userId) {
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
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> acceptCandidate(
    RequestPost post, {
    required String helperId,
    required String helperName,
  }) {
    if (!isOwner(post)) {
      return Future.value(_fail('Only the request owner can choose a helper.'));
    }

    return _run(() async {
      await _postRepository.acceptOffer(
        postId: postId,
        ownerId: post.userId,
        helperId: helperId,
        helperName: helperName,
      );
    });
  }

  Future<bool> respondToInvitation({
    required String notificationId,
    required bool accepted,
  }) {
    final userId = currentUserId;
    if (userId == null) return Future.value(_fail('Please sign in again.'));
    return _run(
      () => _postRepository.respondToInvitation(
        notificationId: notificationId,
        postId: postId,
        helperId: userId,
        accepted: accepted,
      ),
    );
  }

  Future<bool> respondToPendingInvitation(
    bool accepted, {
    String? rejectionMessage,
  }) {
    final userId = currentUserId;
    if (userId == null) return Future.value(_fail('Please sign in again.'));
    return _run(
      () => _postRepository.respondToPendingInvitation(
        postId: postId,
        helperId: userId,
        accepted: accepted,
        rejectionMessage: rejectionMessage,
      ),
    );
  }

  Future<bool> cancelHelperInvitation(RequestPost post) {
    if (!isOwner(post)) {
      return Future.value(
        _fail('Only the requester can cancel this invitation.'),
      );
    }
    return _run(
      () => _postRepository.cancelHelperInvitation(
        postId: postId,
        ownerId: post.userId,
      ),
    );
  }
}
