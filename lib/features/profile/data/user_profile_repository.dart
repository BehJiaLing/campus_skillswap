import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../models/user_profile_summary.dart';
import 'firebase_user_profile_service.dart';

/// Source of truth for student profile data.
class UserProfileRepository {
  UserProfileRepository(this._service);

  final FirebaseUserProfileService _service;

  Future<UserProfile?> getProfile(String userId) async {
    final data = await _service.fetchProfile(userId);
    return data == null ? null : _fromMap(userId, data);
  }

  Stream<UserProfile?> watchProfile(String userId) {
    return _service.watchProfile(userId).map((document) {
      final data = document.data();
      return data == null ? null : _fromMap(document.id, data);
    });
  }

  Future<void> createProfile({
    required String userId,
    required String? email,
    required bool emailVerified,
    required ProfileInput input,
  }) {
    return _service.mergeProfile(userId, {
      'uid': userId,
      'email': email,
      'name': input.name,
      'fullName': input.name,
      'campus': input.campus,
      'school': input.campus,
      'course': input.course,
      'skills': input.skills,
      'photoUrl': '',
      'role': 'user',
      'profileCompleted': true,
      'emailVerified': emailVerified,
      'suspended': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfile(String userId, ProfileInput input) {
    return _service.updateProfile(userId, {
      'name': input.name,
      'fullName': input.name,
      'campus': input.campus,
      'school': input.campus,
      'course': input.course,
      'skills': input.skills,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setOnline(String userId, bool isOnline) {
    return _service.updateProfile(userId, {'isOnline': isOnline});
  }

  Future<UserProfileSummary> getSummary(
    String userId, {
    String? fallbackName,
  }) async {
    final data = await _service.fetchProfile(userId) ?? const {};

    return UserProfileSummary(
      name: _readText(data['name'], fallbackName ?? 'Unknown User'),
      course: _readText(data['course'], 'Student'),
    );
  }

  String _readText(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  UserProfile _fromMap(String id, Map<String, dynamic> data) {
    final rawSkills = data['skills'];
    final skills = rawSkills is Iterable
        ? rawSkills.map((value) => value.toString()).toList(growable: false)
        : rawSkills
                  ?.toString()
                  .split(',')
                  .map((value) => value.trim())
                  .where((value) => value.isNotEmpty)
                  .toList(growable: false) ??
              const <String>[];

    return UserProfile(
      id: id,
      email: _readText(data['email'], ''),
      name: _readText(data['name'] ?? data['fullName'], 'Unknown User'),
      campus: _readText(data['campus'] ?? data['school'], ''),
      course: _readText(data['course'], ''),
      skills: skills,
      role: UserRole.fromValue(data['role']),
      profileCompleted: data['profileCompleted'] == true,
      emailVerified: data['emailVerified'] == true,
      suspended: data['suspended'] == true,
      banned: data['banned'] == true,
      isOnline: data['isOnline'] == true,
      photoUrl: _nullableText(data['profileImageUrl'] ?? data['photoUrl']),
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
      rewardPoints: (data['rewardPoints'] as num?)?.toInt() ?? 0,
    );
  }

  String? _nullableText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
