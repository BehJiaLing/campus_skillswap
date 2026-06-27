import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  final Color navy = const Color(0xFF1A1F5E);
  final Color lightPurple = const Color(0xFFE8E4F8);
  final Color darkBg = const Color(0xFF111827);
  final Color darkCard = const Color(0xFF1F2937);
  final Color darkActive = const Color(0xFF312E81);

  String _getRoleLabel(String role) {
    if (role == 'superadmin') {
      return 'Super Admin';
    }

    if (role == 'admin') {
      return 'Admin';
    }

    return 'User';
  }

  bool _isCurrentRoute(BuildContext context, String route) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    return currentRoute == route;
  }

  Widget _drawerButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required bool isDark,
  }) {
    final isActive = _isCurrentRoute(context, route);

    final Color buttonColor = isDark
        ? isActive
              ? darkActive
              : darkCard
        : isActive
        ? lightPurple
        : Colors.white;

    final Color iconColor = isDark ? Colors.white : navy;
    final Color textColor = isDark ? Colors.white : navy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () {
          Navigator.pop(context);

          if (isActive) return;

          Navigator.pushReplacementNamed(context, route);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(9),
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              if (isActive)
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isDark ? Colors.white : navy,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color drawerBg = isDark ? darkBg : navy;
    final Color avatarBg = isDark ? darkActive : Colors.white;
    final Color avatarTextColor = isDark ? Colors.white : navy;
    final Color mainTextColor = Colors.white;
    final Color subTextColor = Colors.white70;
    final Color footerColor = Colors.white54;

    return Drawer(
      width: 240,
      backgroundColor: drawerBg,
      child: SafeArea(
        child: currentUser == null
            ? const Center(
                child: Text(
                  'No admin logged in',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data() ?? {};

                  final name =
                      (data['name'] ??
                              data['fullName'] ??
                              data['username'] ??
                              currentUser.displayName ??
                              'Admin')
                          .toString();

                  final email = (data['email'] ?? currentUser.email ?? '')
                      .toString();

                  final role = (data['role'] ?? 'admin')
                      .toString()
                      .toLowerCase();

                  final isSuperAdmin = role == 'superadmin';

                  return Column(
                    children: [
                      const SizedBox(height: 18),

                      CircleAvatar(
                        radius: 36,
                        backgroundColor: avatarBg,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: avatarTextColor,
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: mainTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _getRoleLabel(role),
                        style: TextStyle(
                          color: mainTextColor,
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
                          style: TextStyle(color: subTextColor, fontSize: 11),
                        ),
                      ),

                      const SizedBox(height: 24),

                      _drawerButton(
                        context: context,
                        icon: Icons.dashboard_outlined,
                        title: 'Dashboard',
                        route: '/admin/dashboard',
                        isDark: isDark,
                      ),

                      _drawerButton(
                        context: context,
                        icon: Icons.manage_accounts_outlined,
                        title: 'User Management',
                        route: '/admin/user-management',
                        isDark: isDark,
                      ),

                      _drawerButton(
                        context: context,
                        icon: Icons.article_outlined,
                        title: 'Post Management',
                        route: '/admin/post-management',
                        isDark: isDark,
                      ),

                      if (isSuperAdmin)
                        _drawerButton(
                          context: context,
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'User Access',
                          route: '/admin/user-access',
                          isDark: isDark,
                        ),

                      _drawerButton(
                        context: context,
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        route: '/admin/settings',
                        isDark: isDark,
                      ),

                      const Spacer(),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Text(
                          isSuperAdmin
                              ? 'Campus SkillSwap Super Admin'
                              : 'Campus SkillSwap Admin',
                          style: TextStyle(color: footerColor, fontSize: 11),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
