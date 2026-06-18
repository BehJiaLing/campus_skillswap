import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_drawer.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);
  final Color border = const Color(0xFFE0E0F0);
  final Color green = const Color(0xFF4CAF50);
  final Color purple = const Color(0xFFE8E4F8);
  final Color purpleDeep = const Color(0xFF7C5CBF);
  final Color bluePastel = const Color(0xFFE4EEF8);
  final Color mint = const Color(0xFFE4F8F0);
  final Color orange = const Color(0xFFFF9800);
  final Color red = const Color(0xFFE53935);

  String _getSkills(Map<String, dynamic> data) {
    final rawSkills = data['skills'];

    if (rawSkills == null) return 'No skills added';

    if (rawSkills is List) {
      return rawSkills.map((e) => e.toString()).join(', ');
    }

    return rawSkills.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data?.docs ?? [];

          final totalUsers = users.length;

          final activeUsers = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['suspended'] != true;
          }).length;

          final suspendedUsers = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['suspended'] == true;
          }).length;

          final adminUsers = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['role'] == 'admin';
          }).length;

          final recentUsers = users.take(3).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _statCard(
                      title: 'Total Users',
                      value: '$totalUsers',
                      icon: Icons.people_outline,
                      color: navy,
                    ),
                    const SizedBox(width: 10),
                    _statCard(
                      title: 'Active',
                      value: '$activeUsers',
                      icon: Icons.check_circle_outline,
                      color: green,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    _statCard(
                      title: 'Suspended',
                      value: '$suspendedUsers',
                      icon: Icons.block_outlined,
                      color: red,
                    ),
                    const SizedBox(width: 10),
                    _statCard(
                      title: 'Admins',
                      value: '$adminUsers',
                      icon: Icons.admin_panel_settings_outlined,
                      color: orange,
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/users');
                  },
                ),

                const SizedBox(height: 12),

                _actionTile(
                  context,
                  icon: Icons.person_outline,
                  title: 'Admin Profile',
                  subtitle: 'Manage admin profile settings',
                  bgColor: bluePastel,
                  iconColor: navy,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Admin Profile coming soon')),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _actionTile(
                  context,
                  icon: Icons.timeline_outlined,
                  title: 'Audit Track',
                  subtitle: 'Track admin activity and changes',
                  bgColor: mint,
                  iconColor: green,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Audit Track coming soon')),
                    );
                  },
                ),

                const SizedBox(height: 26),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Users',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/admin/users');
                      },
                      child: Text(
                        'See all',
                        style: TextStyle(color: navy),
                      ),
                    ),
                  ],
                ),

                ...recentUsers.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _recentUserTile(data);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
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
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _recentUserTile(Map<String, dynamic> data) {
    final name = data['name'] ?? 'No Name';
    final skills = _getSkills(data);
    final suspended = data['suspended'] ?? false;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: purple,
        child: Text(
          name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFF7C5CBF),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name.toString(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        skills,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: suspended ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
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