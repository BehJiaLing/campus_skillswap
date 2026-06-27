enum UserRole {
  user,
  admin,
  superAdmin;

  factory UserRole.fromValue(Object? value) =>
      switch (value?.toString().trim().toLowerCase()) {
        'admin' => UserRole.admin,
        'superadmin' => UserRole.superAdmin,
        _ => UserRole.user,
      };

  bool get isAdmin => this == UserRole.admin || this == UserRole.superAdmin;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.campus,
    required this.course,
    required this.skills,
    required this.role,
    required this.profileCompleted,
    required this.emailVerified,
    required this.suspended,
    required this.banned,
    required this.isOnline,
    this.photoUrl,
    this.averageRating = 0,
    this.rewardPoints = 0,
  });

  final String id;
  final String email;
  final String name;
  final String campus;
  final String course;
  final List<String> skills;
  final UserRole role;
  final bool profileCompleted;
  final bool emailVerified;
  final bool suspended;
  final bool banned;
  final bool isOnline;
  final String? photoUrl;
  final double averageRating;
  final int rewardPoints;
}

class ProfileInput {
  const ProfileInput({
    required this.name,
    required this.campus,
    required this.course,
    required this.skills,
  });

  final String name;
  final String campus;
  final String course;
  final List<String> skills;
}
