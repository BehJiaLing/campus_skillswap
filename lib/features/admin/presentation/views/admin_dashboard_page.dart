import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_drawer.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);

  final Color darkBg = const Color(0xFF111827);
  final Color darkCard = const Color(0xFF1F2937);
  final Color darkBorder = const Color(0xFF374151);
  final Color darkPurple = const Color(0xFF312E81);

  static const List<Color> chartColors = [
    Color(0xFFFBC695),
    Color(0xFF9485FF),
    Color(0xFF63B4FF),
    Color(0xFFFF9496),
  ];

  String _getName(Map<String, dynamic> data, User? currentUser) {
    return (data['fullName'] ??
            data['name'] ??
            data['username'] ??
            data['displayName'] ??
            currentUser?.displayName ??
            currentUser?.email ??
            'Admin')
        .toString();
  }

  String _getRole(Map<String, dynamic> data) {
    return (data['role'] ?? 'admin').toString().trim().toLowerCase();
  }

  String _roleLabel(String role) {
    if (role == 'superadmin') {
      return 'Super Admin';
    }

    if (role == 'admin') {
      return 'Admin';
    }

    return 'Admin';
  }

  Widget _welcomeCard(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (currentUser == null) {
      return _welcomeCardContent(name: 'Admin', role: 'Admin', isDark: isDark);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};

        final name = _getName(data, currentUser);
        final role = _roleLabel(_getRole(data));

        return _welcomeCardContent(name: name, role: role, isDark: isDark);
      },
    );
  }

  Widget _welcomeCardContent({
    required String name,
    required String role,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? darkPurple : navy,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: const Color(0xFF818CF8).withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back,',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            '$name 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Manage Campus SkillSwap from the dashboard.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _chartCard({required BuildContext context, required bool isDark}) {
    final cardColor = isDark ? darkCard : Colors.white;
    final lineColor = isDark ? darkBorder : const Color(0xFFE0E0F0);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.grey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pie Chart',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            'Programme Pie Chart',
            style: TextStyle(fontSize: 14, color: subTextColor),
          ),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading data: ${snapshot.error}',
                    style: TextStyle(color: textColor),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No users found in database yet.',
                      style: TextStyle(color: subTextColor),
                    ),
                  ),
                );
              }

              Map<String, int> programmeCounts = {
                'Computing / IT': 0,
                'Business & Finance': 0,
                'Engineering': 0,
                'Arts & Others': 0,
              };

              for (final doc in docs) {
                final data = doc.data() as Map<String, dynamic>?;
                final course =
                    (data?['course'] ??
                            data?['studentCourse'] ??
                            data?['programme'] ??
                            data?['program'] ??
                            '')
                        .toString()
                        .toLowerCase();

                if (course.contains('computer') ||
                    course.contains('information') ||
                    course.contains('software') ||
                    course.contains('digital media')) {
                  programmeCounts['Computing / IT'] =
                      programmeCounts['Computing / IT']! + 1;
                } else if (course.contains('business') ||
                    course.contains('accounting') ||
                    course.contains('finance')) {
                  programmeCounts['Business & Finance'] =
                      programmeCounts['Business & Finance']! + 1;
                } else if (course.contains('engineering')) {
                  programmeCounts['Engineering'] =
                      programmeCounts['Engineering']! + 1;
                } else {
                  programmeCounts['Arts & Others'] =
                      programmeCounts['Arts & Others']! + 1;
                }
              }

              programmeCounts.removeWhere((key, value) => value == 0);

              if (programmeCounts.isEmpty) {
                return Center(
                  child: Text(
                    'No data distribution available.',
                    style: TextStyle(color: subTextColor),
                  ),
                );
              }

              return Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = math.min(constraints.maxWidth, 175.0);

                        return SizedBox(
                          height: size,
                          width: size,
                          child: CustomPaint(
                            painter: DynamicPiePainter(
                              data: programmeCounts,
                              colors: chartColors,
                              textColor: Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(programmeCounts.keys.length, (
                        index,
                      ) {
                        final key = programmeCounts.keys.elementAt(index);
                        final labelColor =
                            chartColors[index % chartColors.length];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: labelColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _rankingCard({required bool isDark}) {
    final cardColor = isDark ? darkCard : Colors.white;
    final lineColor = isDark ? darkBorder : const Color(0xFFE0E0F0);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.grey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Helper Ranking',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            'Students ranked by average rating and reward points',
            style: TextStyle(fontSize: 14, color: subTextColor),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _rankingEmptyState(
                  icon: Icons.error_outline_rounded,
                  message: 'Unable to load helper rankings.',
                  color: Colors.redAccent,
                  textColor: subTextColor,
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final students =
                  snapshot.data!.docs
                      .map((document) => _RankedStudent(data: document.data()))
                      .where(
                        (student) =>
                            student.role != 'admin' &&
                            student.role != 'superadmin' &&
                            !student.banned,
                      )
                      .toList()
                    ..sort((first, second) {
                      final ratingOrder = second.rating.compareTo(first.rating);
                      if (ratingOrder != 0) return ratingOrder;
                      final pointsOrder = second.points.compareTo(first.points);
                      if (pointsOrder != 0) return pointsOrder;
                      final reviewOrder = second.ratingCount.compareTo(
                        first.ratingCount,
                      );
                      if (reviewOrder != 0) return reviewOrder;
                      return first.name.toLowerCase().compareTo(
                        second.name.toLowerCase(),
                      );
                    });

              final ranked = students
                  .where(
                    (student) =>
                        student.rating > 0 ||
                        student.points > 0 ||
                        student.ratingCount > 0,
                  )
                  .take(5)
                  .toList();

              if (ranked.isEmpty) {
                return _rankingEmptyState(
                  icon: Icons.emoji_events_outlined,
                  message:
                      'No helper ratings yet. Rankings will appear after completed skill exchanges.',
                  color: subTextColor,
                  textColor: subTextColor,
                );
              }

              return Column(
                children: List.generate(
                  ranked.length,
                  (index) => _rankingRow(
                    student: ranked[index],
                    rank: index + 1,
                    isDark: isDark,
                    showDivider: index < ranked.length - 1,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _rankingRow({
    required _RankedStudent student,
    required int rank,
    required bool isDark,
    required bool showDivider,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final surfaceColor = isDark
        ? const Color(0xFF273449)
        : const Color(0xFFF8F9FD);
    final rankColor = switch (rank) {
      1 => const Color(0xFFFFB300),
      2 => const Color(0xFF90A4AE),
      3 => const Color(0xFFBF7A45),
      _ => const Color(0xFF1A1F5E),
    };

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: rank == 1
                ? rankColor.withValues(alpha: isDark ? .14 : .09)
                : surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: rank == 1
                  ? rankColor.withValues(alpha: .45)
                  : isDark
                  ? darkBorder
                  : const Color(0xFFE8E8F2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: rank <= 3
                    ? Icon(
                        Icons.emoji_events_rounded,
                        color: rankColor,
                        size: 20,
                      )
                    : Text(
                        '$rank',
                        style: TextStyle(
                          color: rankColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              const SizedBox(width: 11),
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFE8E4F8),
                backgroundImage: student.photoUrl.isEmpty
                    ? null
                    : NetworkImage(student.photoUrl),
                child: student.photoUrl.isEmpty
                    ? const Icon(Icons.person_rounded, color: Color(0xFF1A1F5E))
                    : null,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (rank == 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: rankColor.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'TOP',
                              style: TextStyle(
                                color: rankColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      student.course,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 10,
                      runSpacing: 5,
                      children: [
                        _rankingMetric(
                          Icons.star_rounded,
                          student.rating.toStringAsFixed(1),
                          Colors.amber.shade700,
                        ),
                        _rankingMetric(
                          Icons.rate_review_rounded,
                          '${student.ratingCount} reviews',
                          const Color(0xFF7C5CBF),
                        ),
                        _rankingMetric(
                          Icons.workspace_premium_rounded,
                          '${student.points} pts',
                          const Color(0xFF12A875),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const SizedBox(height: 10),
      ],
    );
  }

  Widget _rankingMetric(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _rankingEmptyState({
    required IconData icon,
    required String message,
    required Color color,
    required Color textColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, size: 44, color: color),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pageBg = isDark ? darkBg : bg;
    final appBarColor = isDark ? darkBg : navy;

    return Scaffold(
      backgroundColor: pageBg,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _welcomeCard(context),
            const SizedBox(height: 24),
            _chartCard(context: context, isDark: isDark),
            const SizedBox(height: 24),
            _rankingCard(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _RankedStudent {
  const _RankedStudent({required this.data});

  final Map<String, dynamic> data;

  String get name =>
      (data['name'] ?? data['fullName'] ?? data['displayName'] ?? 'Student')
          .toString();

  String get course {
    final value = (data['course'] ?? data['programme'] ?? '').toString().trim();
    return value.isEmpty ? 'Course not provided' : value;
  }

  String get photoUrl =>
      (data['photoUrl'] ?? data['profileImageUrl'] ?? '').toString().trim();

  String get role => (data['role'] ?? 'user').toString().toLowerCase().trim();

  bool get banned => data['banned'] == true || data['suspended'] == true;

  double get rating => (data['averageRating'] as num?)?.toDouble() ?? 0;

  int get ratingCount => (data['ratingCount'] as num?)?.toInt() ?? 0;

  int get points => (data['rewardPoints'] as num?)?.toInt() ?? 0;
}

class DynamicPiePainter extends CustomPainter {
  final Map<String, int> data;
  final List<Color> colors;
  final Color textColor;

  DynamicPiePainter({
    required this.data,
    required this.colors,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold<int>(0, (totalSum, item) => totalSum + item);

    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);

    final radius = math.min(size.width, size.height) / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;
    int index = 0;

    data.forEach((key, value) {
      final sweepAngle = (value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = colors[index % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      final percentageValue = (value / total) * 100;

      if (percentageValue > 5) {
        final midAngle = startAngle + sweepAngle / 2;

        final textOffset = Offset(
          center.dx + (radius * 0.55) * math.cos(midAngle),
          center.dy + (radius * 0.55) * math.sin(midAngle),
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${percentageValue.toStringAsFixed(0)}%',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        textPainter.paint(
          canvas,
          textOffset - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
      index++;
    });
  }

  @override
  bool shouldRepaint(covariant DynamicPiePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.colors != colors ||
        oldDelegate.textColor != textColor;
  }
}
