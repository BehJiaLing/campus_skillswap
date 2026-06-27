enum RequestPostStatus {
  open,
  matched,
  inProgress,
  completed,
  cancelled;

  factory RequestPostStatus.fromValue(Object? value) {
    return switch (value?.toString().toLowerCase()) {
      'matched' => RequestPostStatus.matched,
      'in_progress' => RequestPostStatus.inProgress,
      'completed' => RequestPostStatus.completed,
      'cancelled' => RequestPostStatus.cancelled,
      _ => RequestPostStatus.open,
    };
  }

  String get firestoreValue => switch (this) {
    RequestPostStatus.inProgress => 'in_progress',
    _ => name,
  };

  String get label => switch (this) {
    RequestPostStatus.open => 'Open',
    RequestPostStatus.matched => 'Matched',
    RequestPostStatus.inProgress => 'In Progress',
    RequestPostStatus.completed => 'Completed',
    RequestPostStatus.cancelled => 'Cancelled',
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
