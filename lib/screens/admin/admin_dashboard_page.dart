import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_drawer.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);

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
    return (data['role'] ?? 'admin').toString().toLowerCase();
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

  Widget _welcomeCard() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return _welcomeCardContent(
        name: 'Admin',
        role: 'Admin',
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
        );
      },
    );
  }

  Widget _welcomeCardContent({
    required String name,
    required String role,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _welcomeCard(),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pie Chart',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const Text(
                    'Programme Pie Chart',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 24),

                  StreamBuilder<QuerySnapshot>(
                    stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading data: ${snapshot.error}',
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
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No users found in database yet.'),
                          ),
                        );
                      }

                      Map<String, int> programmeCounts = {
                        'Computing / IT': 0,
                        'Business & Finance': 0,
                        'Engineering': 0,
                        'Arts & Others': 0,
                      };

                      for (var doc in docs) {
                        final data = doc.data() as Map<String, dynamic>?;
                        final course = (data?['course'] ?? '').toString();

                        if (course.contains('Computer') ||
                            course.contains('Information') ||
                            course.contains('Software') ||
                            course.contains('Digital Media')) {
                          programmeCounts['Computing / IT'] =
                              programmeCounts['Computing / IT']! + 1;
                        } else if (course.contains('Business') ||
                            course.contains('Accounting') ||
                            course.contains('Finance')) {
                          programmeCounts['Business & Finance'] =
                              programmeCounts['Business & Finance']! + 1;
                        } else if (course.contains('Engineering')) {
                          programmeCounts['Engineering'] =
                              programmeCounts['Engineering']! + 1;
                        } else {
                          programmeCounts['Arts & Others'] =
                              programmeCounts['Arts & Others']! + 1;
                        }
                      }

                      programmeCounts.removeWhere((key, value) => value == 0);

                      if (programmeCounts.isEmpty) {
                        return const Center(
                          child: Text('No data distribution available.'),
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final size = min(
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
                                  final key =
                                  programmeCounts.keys.elementAt(index);
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
                                            borderRadius:
                                            BorderRadius.circular(4),
                                          ),
                                        ),

                                        const SizedBox(width: 10),

                                        Expanded(
                                          child: Text(
                                            key,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
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
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ranking',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 20),

                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.star_outline_rounded,
                            size: 48,
                            color: Colors.grey,
                          ),

                          SizedBox(height: 8),

                          Text(
                            'Ranking content feature coming soon',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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

  DynamicPiePainter({
    required this.data,
    required this.colors,
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

    final radius = min(
      size.width,
      size.height,
    ) /
        2;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    double startAngle = -pi / 2;
    int index = 0;

    data.forEach((key, value) {
      final sweepAngle = (value / total) * 2 * pi;

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
          center.dx + (radius * 0.55) * cos(midAngle),
          center.dy + (radius * 0.55) * sin(midAngle),
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${percentageValue.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.black87,
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}