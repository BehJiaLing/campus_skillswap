import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_drawer.dart';
import 'admin_audit_track.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);
  final Color border = const Color(0xFFE0E0F0);
  final Color green = const Color(0xFF4CAF50);
  final Color purple = const Color(0xFFE8E4F8);
  final Color purpleDeep = const Color(0xFF7C5CBF);
  final Color mint = const Color(0xFFE4F8F0);
  final Color red = const Color(0xFFE53935);

  final Color darkBg = const Color(0xFF111827);
  final Color darkCard = const Color(0xFF1F2937);
  final Color darkBorder = const Color(0xFF374151);
  final Color darkInner = const Color(0xFF111827);

  String _getSkills(Map<String, dynamic> data) {
    final rawSkills = data['skills'];

    if (rawSkills == null) return 'No skills added';

    if (rawSkills is List) {
      if (rawSkills.isEmpty) return 'No skills added';
      return rawSkills.map((e) => e.toString()).join(', ');
    }

    return rawSkills.toString();
  }

  Future<void> _openAuditTrack(BuildContext context) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not logged in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final adminDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .get();

    if (!context.mounted) return;

    if (!adminDoc.exists || adminDoc.data() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin profile not found.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final profileData = adminDoc.data()!;
    final userRole =
        profileData['role']?.toString().trim().toLowerCase() ?? 'user';
    final hasAuditAccess = profileData['hasAuditAccess'] == true;

    if (userRole == 'superadmin' || hasAuditAccess) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminAuditTrackPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Access Denied: You do not have permission to view the Audit Track dashboard.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isSuspended(Map<String, dynamic> data) {
    return data['suspended'] == true || data['banned'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pageBg = isDark ? darkBg : bg;
    final textColor = isDark ? Colors.white : const Color(0xFF1F223D);

    return Scaffold(
      backgroundColor: pageBg,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: isDark ? darkBg : navy,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'user')
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (userSnapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${userSnapshot.error}',
                style: TextStyle(
                  color: textColor,
                ),
              ),
            );
          }

          final users = userSnapshot.data?.docs ?? [];

          final totalUsers = users.length;

          final activeUsers = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return !_isSuspended(data);
          }).length;

          final suspendedUsers = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _isSuspended(data);
          }).length;

          final recentUsers = users.take(3).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 12),

                _accountHealthCard(
                  totalUsers: totalUsers,
                  activeUsers: activeUsers,
                  suspendedUsers: suspendedUsers,
                  isDark: isDark,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _smallStatCard(
                      title: 'Total',
                      value: '$totalUsers',
                      icon: Icons.people_outline,
                      color: isDark ? Colors.white : navy,
                      isDark: isDark,
                    ),

                    const SizedBox(width: 10),

                    _smallStatCard(
                      title: 'Active',
                      value: '$activeUsers',
                      icon: Icons.check_circle_outline,
                      color: green,
                      isDark: isDark,
                    ),

                    const SizedBox(width: 10),

                    _smallStatCard(
                      title: 'Suspended',
                      value: '$suspendedUsers',
                      icon: Icons.block_outlined,
                      color: red,
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 12),

                _actionTile(
                  context,
                  icon: Icons.manage_accounts_outlined,
                  title: 'User Management',
                  subtitle: 'View, edit & suspend users',
                  bgColor: purple,
                  iconColor: purpleDeep,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/users');
                  },
                ),

                const SizedBox(height: 12),

                _actionTile(
                  context,
                  icon: Icons.timeline_outlined,
                  title: 'Audit Track',
                  subtitle: 'Track admin activity and deleted user records',
                  bgColor: mint,
                  iconColor: green,
                  isDark: isDark,
                  onTap: () {
                    _openAuditTrack(context);
                  },
                ),

                const SizedBox(height: 26),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Users',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/admin/users');
                      },
                      child: Text(
                        'See all',
                        style: TextStyle(
                          color: isDark ? Colors.white : navy,
                        ),
                      ),
                    ),
                  ],
                ),

                if (recentUsers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ...recentUsers.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _recentUserTile(
                      data,
                      isDark: isDark,
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _accountHealthCard({
    required int totalUsers,
    required int activeUsers,
    required int suspendedUsers,
    required bool isDark,
  }) {
    final int activePercent =
    totalUsers == 0 ? 0 : ((activeUsers / totalUsers) * 100).round();

    final cardColor = isDark ? darkCard : Colors.white;
    final lineColor = isDark ? darkBorder : border;
    final textColor = isDark ? Colors.white : const Color(0xFF1F223D);
    final subTextColor = isDark ? Colors.white60 : Colors.grey;
    final innerColor = isDark ? darkInner : bg;
    final trackColor = isDark ? darkBorder : const Color(0xFFEDEDF6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(
          color: lineColor,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Health',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: textColor,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Active and suspended user distribution',
            style: TextStyle(
              color: subTextColor,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              SizedBox(
                width: 135,
                height: 135,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(135, 135),
                      painter: DonutChartPainter(
                        total: totalUsers,
                        active: activeUsers,
                        suspended: suspendedUsers,
                        activeColor: green,
                        suspendedColor: red,
                        trackColor: trackColor,
                      ),
                    ),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$activePercent%',
                          style: TextStyle(
                            color: isDark ? Colors.white : navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),

                        Text(
                          'Active',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendRow(
                      color: green,
                      title: 'Active Accounts',
                      value: activeUsers,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 14),

                    _legendRow(
                      color: red,
                      title: 'Suspended Accounts',
                      value: suspendedUsers,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: innerColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: lineColor,
                        ),
                      ),
                      child: Text(
                        totalUsers == 0
                            ? 'No user records yet'
                            : '$activeUsers out of $totalUsers accounts are active',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendRow({
    required Color color,
    required String title,
    required int value,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF1F223D);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _smallStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final cardColor = isDark ? darkCard : Colors.white;
    final lineColor = isDark ? darkBorder : border;
    final subTextColor = isDark ? Colors.white60 : Colors.grey;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(
            color: lineColor,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),

            const SizedBox(height: 8),

            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color bgColor,
        required Color iconColor,
        required bool isDark,
        required VoidCallback onTap,
      }) {
    final cardColor = isDark ? darkCard : Colors.white;
    final lineColor = isDark ? darkBorder : border;
    final textColor = isDark ? Colors.white : const Color(0xFF1F223D);
    final subTextColor = isDark ? Colors.white60 : Colors.grey;
    final iconBg = isDark ? bgColor.withValues(alpha: 0.18) : bgColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(
            color: lineColor,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right,
              color: subTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentUserTile(
      Map<String, dynamic> data, {
        required bool isDark,
      }) {
    final name = data['name'] ?? data['fullName'] ?? 'No Name';
    final skills = _getSkills(data);
    final suspended = _isSuspended(data);

    final textColor = isDark ? Colors.white : const Color(0xFF1F223D);
    final subTextColor = isDark ? Colors.white60 : Colors.grey;
    final avatarBg = isDark ? const Color(0xFF312E81) : purple;
    final avatarText = isDark ? Colors.white : purpleDeep;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: avatarBg,
        child: Text(
          name.toString().isNotEmpty
              ? name.toString()[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: avatarText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name.toString(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      subtitle: Text(
        skills,
        style: TextStyle(
          color: subTextColor,
          fontSize: 12,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: suspended
              ? const Color(0xFFFFEBEE)
              : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          suspended ? 'Suspended' : 'Active',
          style: TextStyle(
            color: suspended ? red : green,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final int total;
  final int active;
  final int suspended;
  final Color activeColor;
  final Color suspendedColor;
  final Color trackColor;

  DonutChartPainter({
    required this.total,
    required this.active,
    required this.suspended,
    required this.activeColor,
    required this.suspendedColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final double radius = math.min(
      size.width,
      size.height,
    ) /
        2 -
        10;

    final Rect rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final Paint activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final Paint suspendedPaint = Paint()
      ..color = suspendedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      center,
      radius,
      trackPaint,
    );

    if (total == 0) return;

    const double startAngle = -math.pi / 2;

    final double activeSweep = (active / total) * 2 * math.pi;
    final double suspendedSweep = (suspended / total) * 2 * math.pi;

    if (active > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        activeSweep,
        false,
        activePaint,
      );
    }

    if (suspended > 0) {
      canvas.drawArc(
        rect,
        startAngle + activeSweep,
        suspendedSweep,
        false,
        suspendedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.active != active ||
        oldDelegate.suspended != suspended ||
        oldDelegate.trackColor != trackColor;
  }
}