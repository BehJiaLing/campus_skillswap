import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  final Color navy = const Color(0xFF1A1F5E);
  final Color red = const Color(0xFFE53935);

  String _getRoleLabel(String role) {
    if (role == 'superadmin') {
      return 'Super Admin';
    }

    if (role == 'admin') {
      return 'Admin';
    }

    return 'User';
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }

  Widget _drawerButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 5,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, route);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: navy,
                size: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => _logout(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: red,
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                'Logout',
                style: TextStyle(
                  color: red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Drawer(
      width: 240,
      backgroundColor: navy,
      child: SafeArea(
        child: currentUser == null
            ? Column(
          children: [
            const Spacer(),
            _logoutButton(context),
          ],
        )
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? {};

            final name = (data['name'] ??
                data['fullName'] ??
                data['username'] ??
                currentUser.displayName ??
                'Admin')
                .toString();

            final email =
            (data['email'] ?? currentUser.email ?? '').toString();

            final role =
            (data['role'] ?? 'admin').toString().toLowerCase();

            final isSuperAdmin = role == 'superadmin';

            return Column(
              children: [
                const SizedBox(height: 18),

                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: navy,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _getRoleLabel(role),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    email,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                _drawerButton(
                  context: context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  route: '/admin/dashboard',
                ),

                _drawerButton(
                  context: context,
                  icon: Icons.manage_accounts_outlined,
                  title: 'User Management',
                  route: '/admin/user-management',
                ),

                _drawerButton(
                  context: context,
                  icon: Icons.article_outlined,
                  title: 'Post Management',
                  route: '/admin/post-management',
                ),

                if (isSuperAdmin)
                  _drawerButton(
                    context: context,
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'User Access',
                    route: '/admin/user-access',
                  ),

                _drawerButton(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  route: '/admin/settings',
                ),

                const Spacer(),

                _logoutButton(context),
              ],
            );
          },
        ),
      ),
    );
  }
}