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
      return _welcomeCardContent(
        name: 'Admin',
        role: 'Admin',
        isDark: isDark,
      );
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

        return _welcomeCardContent(
          name: name,
          role: role,
          isDark: isDark,
        );
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
            ? Border.all(
          color: const Color(0xFF818CF8).withValues(alpha: 0.4),
        )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back,',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
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
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard({
    required BuildContext context,
    required bool isDark,
  }) {
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
        border: Border.all(
          color: lineColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.18 : 0.04,
            ),
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
            style: TextStyle(
              fontSize: 14,
              color: subTextColor,
            ),
          ),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading data: ${snapshot.error}',
                    style: TextStyle(
                      color: textColor,
                    ),
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
                      style: TextStyle(
                        color: subTextColor,
                      ),
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
                final course = (data?['course'] ??
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
                    style: TextStyle(
                      color: subTextColor,
                    ),
                  ),
                );
              }

              return Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = math.min(
                          constraints.maxWidth,
                          175.0,
                        );

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
                      children: List.generate(
                        programmeCounts.keys.length,
                            (index) {
                          final key = programmeCounts.keys.elementAt(index);
                          final labelColor =
                          chartColors[index % chartColors.length];

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
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
                        },
                      ),
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

  Widget _rankingCard({
    required bool isDark,
  }) {
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
        border: Border.all(
          color: lineColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.18 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ranking',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.star_outline_rounded,
                    size: 48,
                    color: subTextColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ranking content feature coming soon',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            _chartCard(
              context: context,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            _rankingCard(
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
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
    final total = data.values.fold<int>(
      0,
          (totalSum, item) => totalSum + item,
    );

    if (total == 0) return;

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = math.min(
      size.width,
      size.height,
    ) /
        2;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    double startAngle = -math.pi / 2;
    int index = 0;

    data.forEach((key, value) {
      final sweepAngle = (value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = colors[index % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        true,
        paint,
      );

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
          textOffset -
              Offset(
                textPainter.width / 2,
                textPainter.height / 2,
              ),
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