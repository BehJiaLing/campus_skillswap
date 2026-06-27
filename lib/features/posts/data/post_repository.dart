import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_exception.dart';
import '../models/request_post.dart';
import '../models/request_interactions.dart';
import 'firebase_post_service.dart';

/// Source of truth for request posts.
class PostRepository {
  PostRepository(this._service);

  final FirebasePostService _service;

  Stream<List<RequestPost>> watchAll() {
    return _service.watchAll().map(
      (snapshot) => snapshot.docs.map(_fromDocument).toList(),
    );
  }

  Stream<List<RequestPost>> watchByOwner(String userId) {
    return _service
        .watchByOwner(userId)
        .map((snapshot) => snapshot.docs.map(_fromDocument).toList());
  }

  Stream<RequestPost?> watchOne(String postId) {
    return _service.watchOne(postId).map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return _fromDocument(snapshot);
    });
  }

  Future<void> create(CreateRequestPostInput input) async {
    try {
      await _service.create(input);
    } on FirebaseException catch (error) {
      throw AppException(
        'Unable to publish your request. Please try again.',
        cause: error,
      );
    }
  }

  Stream<List<HelpOffer>> watchOffers(String postId) {
    return _service
        .watchOffers(postId)
        .map(
          (snapshot) => snapshot.docs.map((document) {
            final data = document.data();
            return HelpOffer(
              userId: _text(data['userId'], fallback: document.id),
              userName: _text(data['userName'], fallback: 'Student'),
              course: _text(data['course'], fallback: 'Student'),
              skills: _stringList(data['skills']),
              matchScore: (data['matchScore'] as num?)?.toInt() ?? 0,
              status: _text(data['status'], fallback: 'pending'),
              createdAt: _date(data['createdAt']),
            );
          }).toList(),
        );
  }

  Stream<List<RequestComment>> watchComments(String postId) {
    return _service
        .watchComments(postId)
        .map(
          (snapshot) => snapshot.docs.map((document) {
            final data = document.data();
            return RequestComment(
              id: document.id,
              userId: _text(data['userId']),
              userName: _text(data['userName'], fallback: 'Student'),
              message: _text(data['message']),
              createdAt: _date(data['createdAt']),
            );
          }).toList(),
        );
  }

  Stream<List<RequestRating>> watchRatings(String postId) {
    return _service
        .watchRatings(postId)
        .map(
          (snapshot) => snapshot.docs.map((document) {
            final data = document.data();
            return RequestRating(
              id: document.id,
              fromUserId: _text(data['fromUserId']),
              toUserId: _text(data['toUserId']),
              stars: (data['stars'] as num?)?.toInt() ?? 0,
              review: _text(data['review']),
              createdAt: _date(data['createdAt']),
            );
          }).toList(),
        );
  }

  Future<void> offerHelp(String postId, Map<String, dynamic> data) =>
      _service.offerHelp(postId, data);

  Future<void> addComment(String postId, Map<String, dynamic> data) =>
      _service.addComment(postId, data);

  Future<void> updateStatus(String postId, RequestPostStatus status) =>
      _service.updateStatus(postId, status);

  Future<String> acceptOffer({
    required String postId,
    required String ownerId,
    required String helperId,
    required String helperName,
  }) => _service.acceptOffer(
    postId: postId,
    ownerId: ownerId,
    helperId: helperId,
    helperName: helperName,
  );

  Future<void> addRating(String postId, Map<String, dynamic> data) =>
      _service.addRating(postId, data);

  RequestPost _fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? const <String, dynamic>{};

    return RequestPost(
      id: document.id,
      userId: _text(data['userId']),
      userName: _text(data['userName'], fallback: 'Unknown User'),
      course: _text(data['course'], fallback: 'Student'),
      title: _text(data['title'], fallback: 'No title'),
      description: _text(data['description']),
      skillNeeded: _text(data['skillNeeded']),
      status: RequestPostStatus.fromValue(data['status']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      aiSuggestion: _nullableText(data['aiSuggestion']),
      matchedUserName: _nullableText(data['matchedUserName']),
      matchedUserId: _nullableText(data['matchedUserId']),
      chatId: _nullableText(data['chatId']),
    );
  }

  String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String? _nullableText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  List<String> _stringList(Object? value) {
    if (value is! Iterable) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }
}
