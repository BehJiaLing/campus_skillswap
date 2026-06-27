import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../profile/data/user_profile_repository.dart';
import '../../data/post_repository.dart';
import '../../models/request_post.dart';

class CreatePostViewModel extends ChangeNotifier {
  CreatePostViewModel(
    this._postRepository,
    this._userProfileRepository,
    this._authRepository,
  );

  final PostRepository _postRepository;
  final UserProfileRepository _userProfileRepository;
  final AuthRepository _authRepository;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _authRepository.isSignedIn;

  Future<bool> submit({
    required String title,
    required String description,
    required String skillNeeded,
  }) async {
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    final cleanSkill = skillNeeded.trim();

    if (cleanTitle.isEmpty || cleanDescription.isEmpty || cleanSkill.isEmpty) {
      _errorMessage = 'Please fill in all fields.';
      notifyListeners();
      return false;
    }

    final userId = _authRepository.currentUserId;
    if (userId == null) {
      _errorMessage = 'Your session has expired. Please sign in again.';
      notifyListeners();
      return false;
    }

    _setSubmitting(true);
    _errorMessage = null;

    try {
      final author = await _userProfileRepository.getSummary(
        userId,
        fallbackName: _authRepository.currentUserEmail,
      );

      await _postRepository.create(
        CreateRequestPostInput(
          userId: userId,
          userName: author.name,
          course: author.course,
          title: cleanTitle,
          description: cleanDescription,
          skillNeeded: cleanSkill,
        ),
      );
      return true;
    } on AppException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }
}
