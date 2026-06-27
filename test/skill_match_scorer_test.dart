import 'package:campus_skillswap/features/posts/models/request_interactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exact skill and course match receives the highest score', () {
    final score = SkillMatchScorer.score(
      requestedSkill: 'Flutter',
      requesterCourse: 'Computer Science',
      helperSkills: const ['Python', 'flutter'],
      helperCourse: 'computer science',
    );

    expect(score, 100);
  });

  test('unrelated skill and course receives the baseline score', () {
    final score = SkillMatchScorer.score(
      requestedSkill: 'Canva',
      requesterCourse: 'Design',
      helperSkills: const ['Java'],
      helperCourse: 'Accounting',
    );

    expect(score, 40);
  });
}
