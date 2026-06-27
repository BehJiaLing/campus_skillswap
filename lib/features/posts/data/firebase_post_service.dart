import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/request_post.dart';

/// Lowest-level Firestore adapter for request posts.
class FirebasePostService {
  FirebasePostService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAll() {
    return _posts.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchByOwner(String userId) {
    return _posts
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOne(String postId) {
    return _posts.doc(postId).snapshots();
  }

  Future<void> create(CreateRequestPostInput input) async {
    await _posts.add({
      'userId': input.userId,
      'userName': input.userName,
      'course': input.course,
      'title': input.title,
      'description': input.description,
      'skillNeeded': input.skillNeeded,
      'status': RequestPostStatus.open.firestoreValue,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOffers(String postId) {
    return _posts
        .doc(postId)
        .collection('offers')
        .orderBy('matchScore', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRatings(String postId) {
    return _posts
        .doc(postId)
        .collection('ratings')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> offerHelp(String postId, Map<String, dynamic> data) {
    final userId = data['userId'] as String;
    return _posts.doc(postId).collection('offers').doc(userId).set({
      ...data,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addComment(String postId, Map<String, dynamic> data) {
    return _posts.doc(postId).collection('comments').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus(String postId, RequestPostStatus status) {
    return _posts.doc(postId).update({
      'status': status.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> acceptOffer({
    required String postId,
    required String ownerId,
    required String helperId,
    required String helperName,
  }) async {
    final chatId = 'request_$postId';
    final batch = _firestore.batch();
    final post = _posts.doc(postId);
    final chat = _firestore.collection('chats').doc(chatId);

    batch.update(post, {
      'status': RequestPostStatus.matched.firestoreValue,
      'matchedUserId': helperId,
      'matchedUserName': helperName,
      'chatId': chatId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(chat, {
      'userIDs': [ownerId, helperId],
      'postId': postId,
      'lastMessage': 'You are matched for this skill request.',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.update(post.collection('offers').doc(helperId), {
      'status': 'accepted',
    });
    await batch.commit();
    return chatId;
  }

  Future<void> addRating(String postId, Map<String, dynamic> data) {
    final fromUserId = data['fromUserId'] as String;
    return _posts.doc(postId).collection('ratings').doc(fromUserId).set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
