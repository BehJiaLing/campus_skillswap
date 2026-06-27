import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/request_post.dart';
import '../models/ai_match.dart';

/// Lowest-level Firestore adapter for request posts.
class FirebasePostService {
  FirebasePostService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

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

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAiMatches(String postId) {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('ai_matches')
        .orderBy('matchPercentage', descending: true)
        .snapshots();
  }

  Future<void> saveAiMatches(String postId, List<AiMatch> matches) async {
    final ref = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('ai_matches');

    final oldMatches = await ref.get();
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in oldMatches.docs) {
      batch.delete(doc.reference);
    }

    for (final match in matches) {
      batch.set(ref.doc(match.userId), {
        'userId': match.userId,
        'userName': match.userName,
        'course': match.course,
        'skills': match.skills,
        'matchPercentage': match.matchPercentage,
        'reason': match.reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> offerHelp(String postId, Map<String, dynamic> data) async {
    final userId = data['userId'] as String;
    final post = await _posts.doc(postId).get();
    final postData = post.data() ?? const <String, dynamic>{};
    final batch = _firestore.batch();
    batch.set(_posts.doc(postId).collection('offers').doc(userId), {
      ...data,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    final ownerId = postData['userId']?.toString() ?? '';
    if (ownerId.isNotEmpty) {
      batch.set(_notifications.doc(), {
        'recipientId': ownerId,
        'senderId': userId,
        'senderName': data['userName'] ?? 'A student',
        'type': 'helper_offer',
        'postId': postId,
        'postTitle': postData['title'] ?? 'Skill request',
        'message':
            '${data['userName'] ?? 'A student'} offered to help with your request.',
        'status': 'info',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotifications(
    String userId,
  ) {
    return _notifications.where('recipientId', isEqualTo: userId).snapshots();
  }

  Future<void> markNotificationRead(String notificationId) {
    return _notifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> addComment(String postId, Map<String, dynamic> data) async {
    final post =
        (await _posts.doc(postId).get()).data() ?? const <String, dynamic>{};
    final batch = _firestore.batch();
    batch.set(_posts.doc(postId).collection('comments').doc(), {
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final ownerId = post['userId']?.toString() ?? '';
    final commenterId = data['userId']?.toString() ?? '';
    if (ownerId.isNotEmpty && ownerId != commenterId) {
      batch.set(_notifications.doc(), {
        'recipientId': ownerId,
        'senderId': commenterId,
        'senderName': data['userName'] ?? 'A student',
        'type': 'post_comment',
        'postId': postId,
        'postTitle': post['title'] ?? 'Skill request',
        'message':
            '${data['userName'] ?? 'A student'} commented: "${data['message'] ?? ''}"',
        'status': 'info',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> updatePost(String postId, UpdateRequestPostInput input) {
    return _posts.doc(postId).update({
      'title': input.title.trim(),
      'skillNeeded': input.skillNeeded.trim(),
      'description': input.description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> softDeletePost(String postId, String userId) async {
    final postRef = _posts.doc(postId);
    final snapshot = await postRef.get();
    final data = snapshot.data();
    if (data == null || data['userId'] != userId) {
      throw Exception('Only the post owner can delete this post.');
    }
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('deleted_posts_history').doc(postId),
      {
        ...data,
        'postId': postId,
        'originalData': data,
        'previousStatus': data['status'] ?? 'open',
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedByUid': userId,
        'deletedByEmail': 'Post owner',
        'isRestored': false,
      },
      SetOptions(merge: true),
    );
    batch.update(postRef, {
      'isDeleted': true,
      'previousStatus': data['status'] ?? 'open',
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedByUid': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
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

    final postRef = _posts.doc(postId);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final offersRef = postRef.collection('offers');

    final offersSnapshot = await offersRef.get();
    final selectedExistingOffer = offersSnapshot.docs.any(
      (doc) => doc.id == helperId,
    );

    if (!selectedExistingOffer) {
      final postSnapshot = await postRef.get();
      final post = postSnapshot.data() ?? const <String, dynamic>{};
      batch.update(postRef, {
        'pendingHelperId': helperId,
        'pendingHelperName': helperName,
        'chatId': chatId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(chatRef, {
        'userIDs': [ownerId, helperId],
        'postId': postId,
        'lastMessage': 'Helper invitation sent.',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(_notifications.doc(), {
        'recipientId': helperId,
        'senderId': ownerId,
        'senderName': post['userName'] ?? 'A requester',
        'type': 'helper_invitation',
        'postId': postId,
        'postTitle': post['title'] ?? 'Skill request',
        'message':
            '${post['userName'] ?? 'A requester'} invited you to help with this request.',
        'status': 'pending',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      for (final offer in offersSnapshot.docs) {
        final offerData = offer.data();
        if (offerData['status'] != null && offerData['status'] != 'pending') {
          continue;
        }
        batch.set(_notifications.doc(), {
          'recipientId': offer.id,
          'senderId': ownerId,
          'senderName': post['userName'] ?? 'The requester',
          'type': 'offer_on_hold',
          'postId': postId,
          'postTitle': post['title'] ?? 'Skill request',
          'message':
              '${post['userName'] ?? 'The requester'} is waiting for another invited helper to reply. Your offer remains on hold.',
          'status': 'pending',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return '';
    }

    batch.update(postRef, {
      'status': RequestPostStatus.matched.firestoreValue,
      'matchedUserId': helperId,
      'matchedUserName': helperName,
      'chatId': chatId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(chatRef, {
      'userIDs': [ownerId, helperId],
      'postId': postId,
      'lastMessage': 'You are matched for this skill request.',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    for (final doc in offersSnapshot.docs) {
      if (doc.id == helperId) {
        batch.set(doc.reference, {
          'status': 'accepted',
          'statusMessage':
              'Congratulations! You have been selected as the helper for this request.',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        batch.set(doc.reference, {
          'status': 'rejected',
          'statusMessage':
              'Another helper has been selected for this request. Thank you for offering your support.',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        final rejectedData = doc.data();
        batch.set(_notifications.doc(), {
          'recipientId': doc.id,
          'senderId': ownerId,
          'senderName': 'Request owner',
          'type': 'offer_rejected',
          'postId': postId,
          'postTitle': 'Skill request',
          'message':
              '${rejectedData['userName'] ?? 'Student'}, another helper was selected for this request.',
          'status': 'rejected',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    batch.set(_notifications.doc(), {
      'recipientId': helperId,
      'senderId': ownerId,
      'senderName': 'Request owner',
      'type': 'offer_accepted',
      'postId': postId,
      'postTitle': 'Skill request',
      'message': 'Your helper offer was accepted. You can now start chatting.',
      'status': 'accepted',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_notifications.doc(), {
      'recipientId': ownerId,
      'senderId': helperId,
      'senderName': helperName,
      'type': 'post_status',
      'postId': postId,
      'postTitle': 'Skill request',
      'message': 'Your post status changed to MATCHED with $helperName.',
      'status': 'info',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return chatId;
  }

  Future<void> respondToInvitation({
    required String notificationId,
    required String postId,
    required String helperId,
    required bool accepted,
    String? rejectionMessage,
  }) async {
    final postRef = _posts.doc(postId);
    final postSnapshot = await postRef.get();
    final post = postSnapshot.data();
    if (post == null || post['pendingHelperId'] != helperId) {
      throw Exception('This invitation is no longer available.');
    }
    final ownerId = post['userId']?.toString() ?? '';
    final helperName = post['pendingHelperName']?.toString() ?? 'Helper';
    final batch = _firestore.batch();
    batch.update(_notifications.doc(notificationId), {
      'status': accepted ? 'accepted' : 'rejected',
      'isRead': true,
      'respondedAt': FieldValue.serverTimestamp(),
    });
    if (accepted) {
      final chatId = 'request_$postId';
      batch.update(postRef, {
        'status': RequestPostStatus.matched.firestoreValue,
        'matchedUserId': helperId,
        'matchedUserName': helperName,
        'chatId': chatId,
        'pendingHelperId': FieldValue.delete(),
        'pendingHelperName': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(_firestore.collection('chats').doc(chatId), {
        'userIDs': [ownerId, helperId],
        'postId': postId,
        'lastMessage': 'You are matched for this skill request.',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      batch.update(postRef, {
        'pendingHelperId': FieldValue.delete(),
        'pendingHelperName': FieldValue.delete(),
        'chatId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final chatId = post['chatId']?.toString();
      if (chatId != null && chatId.isNotEmpty) {
        batch.delete(_firestore.collection('chats').doc(chatId));
      }
    }
    batch.set(_notifications.doc(), {
      'recipientId': ownerId,
      'senderId': helperId,
      'senderName': helperName,
      'type': accepted ? 'invitation_accepted' : 'invitation_rejected',
      'postId': postId,
      'postTitle': post['title'] ?? 'Skill request',
      'message': accepted
          ? '$helperName accepted your helper invitation.'
          : rejectionMessage?.trim().isNotEmpty == true
          ? '$helperName declined your helper invitation: ${rejectionMessage!.trim()}'
          : '$helperName declined your helper invitation.',
      'status': accepted ? 'accepted' : 'rejected',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (accepted) {
      batch.set(_notifications.doc(), {
        'recipientId': ownerId,
        'senderId': helperId,
        'senderName': helperName,
        'type': 'post_status',
        'postId': postId,
        'postTitle': post['title'] ?? 'Skill request',
        'message': 'Your post status changed to MATCHED with $helperName.',
        'status': 'info',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> respondToPendingInvitation({
    required String postId,
    required String helperId,
    required bool accepted,
    String? rejectionMessage,
  }) async {
    final snapshot = await _notifications
        .where('recipientId', isEqualTo: helperId)
        .get();
    final invitations = snapshot.docs.where((document) {
      final data = document.data();
      return data['postId'] == postId &&
          data['type'] == 'helper_invitation' &&
          data['status'] == 'pending';
    });
    if (invitations.isEmpty) {
      throw Exception('This invitation is no longer available.');
    }
    await respondToInvitation(
      notificationId: invitations.first.id,
      postId: postId,
      helperId: helperId,
      accepted: accepted,
      rejectionMessage: rejectionMessage,
    );
  }

  Future<void> cancelHelperInvitation({
    required String postId,
    required String ownerId,
  }) async {
    final postRef = _posts.doc(postId);
    final snapshot = await postRef.get();
    final post = snapshot.data();
    if (post == null || post['userId'] != ownerId) {
      throw Exception('Only the requester can cancel this invitation.');
    }
    final helperId = post['pendingHelperId']?.toString();
    final helperName = post['pendingHelperName']?.toString() ?? 'Helper';
    if (helperId == null || helperId.isEmpty) {
      throw Exception('There is no pending invitation to cancel.');
    }
    final notificationSnapshot = await _notifications
        .where('recipientId', isEqualTo: helperId)
        .get();
    final batch = _firestore.batch();
    batch.update(postRef, {
      'pendingHelperId': FieldValue.delete(),
      'pendingHelperName': FieldValue.delete(),
      'chatId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final chatId = post['chatId']?.toString();
    if (chatId != null && chatId.isNotEmpty) {
      batch.delete(_firestore.collection('chats').doc(chatId));
    }
    for (final document in notificationSnapshot.docs) {
      final data = document.data();
      if (data['postId'] == postId &&
          data['type'] == 'helper_invitation' &&
          data['status'] == 'pending') {
        batch.update(document.reference, {
          'status': 'cancelled',
          'isRead': false,
          'message': 'The helper invitation for this request was cancelled.',
          'respondedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    batch.set(_notifications.doc(), {
      'recipientId': ownerId,
      'senderId': helperId,
      'senderName': helperName,
      'type': 'invitation_cancelled',
      'postId': postId,
      'postTitle': post['title'] ?? 'Skill request',
      'message': 'You cancelled the invitation sent to $helperName.',
      'status': 'cancelled',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> addRating(String postId, Map<String, dynamic> data) async {
    final fromUserId = data['fromUserId'] as String;
    final toUserId = data['toUserId'] as String;
    final stars = (data['stars'] as num).toInt().clamp(1, 5);
    final userRef = _firestore.collection('users').doc(toUserId);
    final ratingRef = _posts.doc(postId).collection('ratings').doc(fromUserId);
    await _firestore.runTransaction((transaction) async {
      final post =
          (await transaction.get(_posts.doc(postId))).data() ??
          const <String, dynamic>{};
      final user =
          (await transaction.get(userRef)).data() ?? const <String, dynamic>{};
      final existingRating = await transaction.get(ratingRef);
      if (existingRating.exists || post['status'] == 'completed') {
        throw Exception('This post was already completed and rated.');
      }
      final oldCount = (user['ratingCount'] as num?)?.toInt() ?? 0;
      final oldTotal =
          (user['ratingTotal'] as num?)?.toDouble() ??
          ((user['averageRating'] as num?)?.toDouble() ?? 0) * oldCount;
      final newCount = oldCount + 1;
      final newTotal = oldTotal + stars;
      final newAverage = newTotal / newCount;
      final newPoints =
          ((user['rewardPoints'] as num?)?.toInt() ?? 0) + stars * 20;
      transaction.set(ratingRef, {
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(userRef, {
        'ratingCount': newCount,
        'ratingTotal': newTotal,
        'averageRating': newAverage,
        'rewardPoints': FieldValue.increment(stars * 20),
      }, SetOptions(merge: true));
      transaction.update(_posts.doc(postId), {
        'status': RequestPostStatus.completed.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final review = data['review']?.toString().trim() ?? '';
      transaction.set(_notifications.doc(), {
        'recipientId': toUserId,
        'senderId': fromUserId,
        'senderName': post['userName'] ?? 'Request owner',
        'type': 'rating_received',
        'postId': postId,
        'postTitle': post['title'] ?? 'Skill request',
        'message': review.isEmpty
            ? 'You received $stars stars. Your rating is now ${newAverage.toStringAsFixed(1)} and you have $newPoints points.'
            : 'You received $stars stars: "$review". Your rating is now ${newAverage.toStringAsFixed(1)} and you have $newPoints points.',
        'status': 'info',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(_notifications.doc(), {
        'recipientId': fromUserId,
        'senderId': toUserId,
        'senderName': data['helperName'] ?? 'Matched helper',
        'type': 'post_status',
        'postId': postId,
        'postTitle': post['title'] ?? 'Skill request',
        'message':
            'Your post status changed to DONE. The helper rating and points were saved.',
        'status': 'info',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
