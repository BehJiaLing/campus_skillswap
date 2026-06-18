import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  final Color navy = const Color(0xFF1A1F5E);

  String _getText(
      Map<String, dynamic> data,
      List<String> keys,
      String fallback,
      ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _profileAvatar({
    required String profileImageUrl,
    required String firstLetter,
  }) {
    return CircleAvatar(
      radius: 42,
      backgroundColor: Colors.white,
      child: profileImageUrl.isNotEmpty
          ? ClipOval(
        child: Image.network(
          profileImageUrl,
          width: 84,
          height: 84,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              firstLetter,
              style: const TextStyle(
                color: Color(0xFF1A1F5E),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      )
          : Text(
        firstLetter,
        style: const TextStyle(
          color: Color(0xFF1A1F5E),
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null) {
      return Drawer(
        backgroundColor: navy,
        child: const Center(
          child: Text(
            'No user logged in',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: navy,
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(authUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? {};

            final name = _getText(
              data,
              [
                'fullName',
                'name',
                'username',
                'displayName',
                'studentName',
              ],
              authUser.displayName ?? 'Admin',
            );

            final role = _capitalize(
              _getText(
                data,
                ['role'],
                'admin',
              ),
            );

            final email = authUser.email ??
                _getText(
                  data,
                  ['email'],
                  'admin@email.com',
                );

            final profileImageUrl = _getText(
              data,
              [
                'profileImageUrl',
                'photoUrl',
                'photoURL',
                'profileImage',
                'profilePicture',
              ],
              authUser.photoURL ?? '',
            );

            final firstLetter = name.isNotEmpty
                ? name[0].toUpperCase()
                : email[0].toUpperCase();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  _profileAvatar(
                    profileImageUrl: profileImageUrl,
                    firstLetter: firstLetter,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    role,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    email,
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
                      Navigator.pushReplacementNamed(
                        context,
                        '/admin/dashboard',
                      );
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
                    icon: Icons.article_outlined,
                    label: 'Post Management',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(
                        context,
                        '/admin/post-management',
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
            );
          },
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