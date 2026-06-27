import 'package:cloud_firestore/cloud_firestore.dart';

/// Lowest-level Firestore adapter for user profiles.
class FirebaseUserProfileService {
  FirebaseUserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    return snapshot.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  Future<void> mergeProfile(String userId, Map<String, dynamic> data) {
    return _firestore
        .collection('users')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) {
    return _firestore.collection('users').doc(userId).update(data);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchAllProfiles() {
    return FirebaseFirestore.instance.collection('users').get();
  }
}
