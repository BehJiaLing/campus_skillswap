enum RequestPostStatus {
  open,
  matched,
  completed,
  // Kept only so older Firestore records remain readable.
  inProgress,
  cancelled;

  factory RequestPostStatus.fromValue(Object? value) {
    return switch (value?.toString().toLowerCase()) {
      'matched' => RequestPostStatus.matched,
      'in_progress' => RequestPostStatus.matched,
      'completed' => RequestPostStatus.completed,
      'cancelled' => RequestPostStatus.cancelled,
      _ => RequestPostStatus.open,
    };
  }

  String get firestoreValue => switch (this) {
    RequestPostStatus.inProgress => 'matched',
    _ => name,
  };

  String get label => switch (this) {
    RequestPostStatus.open => 'Open',
    RequestPostStatus.matched => 'Matched',
    RequestPostStatus.inProgress => 'Matched',
    RequestPostStatus.completed => 'Done',
    RequestPostStatus.cancelled => 'Done',
  };
}

/// Immutable domain model used by the post views and ViewModels.
class RequestPost {
  const RequestPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.course,
    required this.title,
    required this.description,
    required this.skillNeeded,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.aiSuggestion,
    this.matchedUserName,
    this.matchedUserId,
    this.chatId,
    this.pendingHelperName,
    this.pendingHelperId,
  });

  final String id;
  final String userId;
  final String userName;
  final String course;
  final String title;
  final String description;
  final String skillNeeded;
  final RequestPostStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? aiSuggestion;
  final String? matchedUserName;
  final String? matchedUserId;
  final String? chatId;
  final String? pendingHelperName;
  final String? pendingHelperId;
}

class CreateRequestPostInput {
  const CreateRequestPostInput({
    required this.userId,
    required this.userName,
    required this.course,
    required this.title,
    required this.description,
    required this.skillNeeded,
  });

  final String userId;
  final String userName;
  final String course;
  final String title;
  final String description;
  final String skillNeeded;
}
