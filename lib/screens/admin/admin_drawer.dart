import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  final Color navy = const Color(0xFF1A1F5E);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: navy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Column(
            children: [
              const SizedBox(height: 20),

              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                child: Text(
                  user?.email != null ? user!.email![0].toUpperCase() : 'A',
                  style: TextStyle(
                    color: navy,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                user?.email ?? 'admin@email.com',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 40),

              _drawerButton(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/admin/dashboard');
                },
              ),

              const SizedBox(height: 12),

              _drawerButton(
                icon: Icons.manage_accounts_outlined,
                label: 'User Management',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(
                    context,
                    '/admin/user-management',
                  );
                },
              ),

              const SizedBox(height: 12),

              _drawerButton(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile coming soon')),
                  );
                },
              ),

              const Spacer(),

              _drawerButton(
                icon: Icons.logout,
                label: 'Logout',
                isLogout: true,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();

                  if (!context.mounted) return;

                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: isLogout ? const Color(0xFFFFEBEE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red : navy,
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isLogout ? Colors.red : navy,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}