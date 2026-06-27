class AiMatch {
  const AiMatch({
    required this.userId,
    required this.userName,
    required this.course,
    required this.skills,
    required this.matchPercentage,
    required this.reason,
  });

  final String userId;
  final String userName;
  final String course;
  final List<String> skills;
  final int matchPercentage;
  final String reason;
}
