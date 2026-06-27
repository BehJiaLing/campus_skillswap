import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../features/posts/models/request_interactions.dart';
import '../../features/posts/models/request_post.dart';
import '../../features/profile/models/user_profile.dart';

class GroqRankedCandidate {
  const GroqRankedCandidate({
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

class GroqMatchingService {
  GroqMatchingService({http.Client? client})
    : _client = client ?? http.Client();

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'openai/gpt-oss-20b';

  final http.Client _client;

  Future<List<GroqRankedCandidate>> matchProfiles({
    required RequestPost post,
    required List<UserProfile> users,
  }) async {
    final candidates =
        users
            .where(
              (user) =>
                  user.id != post.userId &&
                  !user.role.isAdmin &&
                  !user.suspended &&
                  !user.banned &&
                  user.profileCompleted,
            )
            .map(
              (user) => <String, dynamic>{
                'userId': user.id,
                'userName': user.name,
                'course': user.course,
                'skills': user.skills,
                'averageRating': user.averageRating,
                'rewardPoints': user.rewardPoints,
                'ruleScore': _ruleBasedScore(post, user),
              },
            )
            .where((candidate) => (candidate['ruleScore'] as int) > 0)
            .toList()
          ..sort(
            (a, b) => (b['ruleScore'] as int).compareTo(a['ruleScore'] as int),
          );

    return _rank(
      post: post,
      candidates: candidates.take(5).toList(growable: false),
      task:
          'These five profiles were selected by deterministic rule-based filtering. Rank the three most suitable profiles.',
    );
  }

  Future<List<GroqRankedCandidate>> rankOffers({
    required RequestPost post,
    required List<HelpOffer> offers,
  }) {
    final candidates = offers
        .map(
          (offer) => <String, dynamic>{
            'userId': offer.userId,
            'userName': offer.userName,
            'course': offer.course,
            'skills': offer.skills,
            'ruleScore': offer.matchScore,
            'offerStatus': offer.status,
          },
        )
        .toList(growable: false);

    return _rank(
      post: post,
      candidates: candidates,
      task:
          'Every candidate actively offered to help. Rank the three most suitable offers using skills, course relevance, and ruleScore.',
    );
  }

  Future<List<GroqRankedCandidate>> _rank({
    required RequestPost post,
    required List<Map<String, dynamic>> candidates,
    required String task,
  }) async {
    if (candidates.isEmpty) return const [];

    final apiKey = dotenv.env['GROQ_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Groq API key is missing in assets/.env');
    }

    final prompt =
        '''
You rank helpers for a campus peer-to-peer skill exchange.

Request:
- title: ${post.title}
- skill needed: ${post.skillNeeded}
- description: ${post.description}
- requester course: ${post.course}

Candidate data:
${jsonEncode(candidates)}

Task: $task

Return at most three candidates. Only use userId values from the candidate data.
Give each a matchPercentage from 0 to 100 and a concise, specific reason.
Return exactly one JSON object in this form:
{"rankings":[{"userId":"id","matchPercentage":90,"reason":"reason"}]}
''';

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'temperature': 0.2,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq could not rank candidates. Please try again.');
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    final content = responseBody['choices']?[0]?['message']?['content'];
    if (content == null) throw Exception('Groq returned an empty response.');

    final decoded = jsonDecode(content.toString()) as Map<String, dynamic>;
    final rankings = decoded['rankings'] as List? ?? const [];
    final candidatesById = {
      for (final candidate in candidates)
        candidate['userId'].toString(): candidate,
    };

    final results = <GroqRankedCandidate>[];
    for (final item in rankings) {
      if (item is! Map) continue;
      final userId = item['userId']?.toString() ?? '';
      final candidate = candidatesById[userId];
      if (candidate == null ||
          results.any((result) => result.userId == userId)) {
        continue;
      }
      final percentage = int.tryParse(item['matchPercentage'].toString()) ?? 0;
      results.add(
        GroqRankedCandidate(
          userId: userId,
          userName: candidate['userName']?.toString() ?? 'Student',
          course: candidate['course']?.toString() ?? '',
          skills: (candidate['skills'] as List? ?? const [])
              .map((skill) => skill.toString())
              .toList(growable: false),
          matchPercentage: percentage.clamp(0, 100),
          reason: item['reason']?.toString().trim().isNotEmpty == true
              ? item['reason'].toString().trim()
              : 'Suitable based on skill and course relevance.',
        ),
      );
      if (results.length == 3) break;
    }

    return results;
  }

  int _ruleBasedScore(RequestPost post, UserProfile user) {
    var score = 0;
    final neededSkill = post.skillNeeded.trim().toLowerCase();
    final userCourse = user.course.toLowerCase();
    final userSkills = user.skills
        .map((skill) => skill.trim().toLowerCase())
        .where((skill) => skill.isNotEmpty);

    for (final skill in userSkills) {
      if (skill == neededSkill) {
        score += 50;
      } else if (skill.contains(neededSkill) || neededSkill.contains(skill)) {
        score += 40;
      } else if (_isRelatedSkill(neededSkill, skill)) {
        score += 30;
      }
    }
    if (_isRelatedCourse(neededSkill, userCourse)) score += 20;
    score += (user.averageRating * 3).round();
    if (user.rewardPoints >= 100) {
      score += 10;
    } else if (user.rewardPoints >= 50) {
      score += 5;
    }
    return score.clamp(0, 100);
  }

  bool _isRelatedSkill(String needed, String offered) {
    const groups = [
      [
        'python',
        'java',
        'flutter',
        'dart',
        'firebase',
        'coding',
        'programming',
        'web',
        'html',
        'css',
        'javascript',
        'database',
        'sql',
        'mysql',
        'mongodb',
        'api',
        'react',
        'node',
        'php',
        'c++',
        'c#',
      ],
      [
        'design',
        'ui',
        'ux',
        'figma',
        'poster',
        'canva',
        'photoshop',
        'illustrator',
      ],
      ['presentation', 'public speaking', 'speaking', 'slides', 'powerpoint'],
      ['writing', 'report', 'essay', 'grammar', 'english', 'malay'],
    ];
    return groups.any(
      (group) => group.any(needed.contains) && group.any(offered.contains),
    );
  }

  bool _isRelatedCourse(String skill, String course) {
    const technicalSkills = [
      'python',
      'java',
      'flutter',
      'dart',
      'firebase',
      'coding',
      'programming',
      'database',
      'web',
      'sql',
      'api',
      'react',
      'node',
      'software',
    ];
    const technicalCourses = [
      'computer',
      'computing',
      'software',
      'information technology',
      'data',
      'cyber',
    ];
    return technicalSkills.any(skill.contains) &&
        technicalCourses.any(course.contains);
  }
}
