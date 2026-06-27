class HelpOffer {
  const HelpOffer({
    required this.userId,
    required this.userName,
    required this.course,
    required this.campus,
    required this.skills,
    required this.matchScore,
    required this.status,
    this.createdAt,
  });

  final String userId;
  final String userName;
  final String course;
  final String campus;
  final List<String> skills;
  final int matchScore;
  final String status;
  final DateTime? createdAt;
}

class RequestComment {
  const RequestComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime? createdAt;
}

class RequestRating {
  const RequestRating({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.stars,
    required this.review,
    this.createdAt,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final int stars;
  final String review;
  final DateTime? createdAt;
}

class SkillMatchScorer {
  const SkillMatchScorer._();

  static int score({
    required String requestedSkill,
    required String requesterCourse,
    required List<String> helperSkills,
    required String helperCourse,
  }) {
    final requested = requestedSkill.trim().toLowerCase();
    final hasSkill = helperSkills.any((skill) {
      final normalized = skill.trim().toLowerCase();
      return normalized.isNotEmpty &&
          (requested.contains(normalized) || normalized.contains(requested));
    });
    return (hasSkill ? 80 : 40) +
        (helperCourse.trim().toLowerCase() ==
                requesterCourse.trim().toLowerCase()
            ? 20
            : 0);
  }
}
