import 'package:flutter/foundation.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../posts/data/post_repository.dart';
import '../../models/app_notification.dart';

class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel(this._repository, this._authRepository) {
    final userId = _authRepository.currentUserId;
    notifications = userId == null
        ? Stream.value(const <AppNotification>[])
        : _repository.watchNotifications(userId);
  }

  final PostRepository _repository;
  final AuthRepository _authRepository;
  late final Stream<List<AppNotification>> notifications;
  bool busy = false;
  String? errorMessage;

  String? get currentUserId => _authRepository.currentUserId;

  Future<bool> respond(
    AppNotification notification,
    bool accepted, {
    String? rejectionMessage,
  }) async {
    final userId = currentUserId;
    if (userId == null) return false;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.respondToInvitation(
        notificationId: notification.id,
        postId: notification.postId,
        helperId: userId,
        accepted: accepted,
        rejectionMessage: rejectionMessage,
      );
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) => _repository.markNotificationRead(id);
}
