import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/app_theme.dart';
import 'admin_drawer.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);
  final Color darkBg = const Color(0xFF111827);
  final Color darkCard = const Color(0xFF1F2937);
  final Color darkBorder = const Color(0xFF374151);
  final Color border = const Color(0xFFE0E0F0);
  final Color purple = const Color(0xFFE8E4F8);
  final Color purpleDeep = const Color(0xFF7C5CBF);

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

  Future<void> _changePassword(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No email found for this account")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent successfully")),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to send reset email: $e")));
    }
  }

  Future<void> _logout(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'isOnline': false,
        }, SetOptions(merge: true));
      }

      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logout failed: $e")));
    }
  }

  void _showEditNameDialog(
    BuildContext context,
    String currentName,
    String uid,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? darkCard : Colors.white,
          title: Text(
            'Edit Admin Name',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: TextField(
            controller: nameController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = nameController.text.trim();

                if (newName.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .set({
                      'name': newName,
                      'fullName': newName,
                    }, SetOptions(merge: true));

                if (!context.mounted) return;

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pageBg = isDark ? darkBg : bg;
    final cardColor = isDark ? darkCard : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F223D);
    final subTextColor = isDark ? Colors.white70 : Colors.grey;
    final sectionTextColor = isDark ? Colors.white70 : Colors.black54;
    final lineColor = isDark ? darkBorder : border;
    final avatarBg = isDark ? const Color(0xFF312E81) : purple;
    final iconColor = isDark ? Colors.white : navy;

    return Scaffold(
      backgroundColor: pageBg,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: 'Open navigation menu',
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      body: authUser == null
          ? Center(
              child: Text(
                'No active administrative session.',
                style: TextStyle(color: textColor),
              ),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(authUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data?.data() ?? {};

                final name = _getText(data, ['name', 'fullName'], 'Admin User');

                final rawRole = _getText(data, ['role'], 'admin');

                final email =
                    authUser.email ??
                    _getText(data, ['email'], 'admin@email.com');

                final profileImageUrl = _getText(data, [
                  'profileImageUrl',
                  'photoUrl',
                ], '');

                final firstLetter = name.isNotEmpty
                    ? name[0].toUpperCase()
                    : '?';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: lineColor),
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
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 45,
                                  backgroundColor: avatarBg,
                                  child: profileImageUrl.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            profileImageUrl,
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Text(
                                                    firstLetter,
                                                    style: TextStyle(
                                                      color: purpleDeep,
                                                      fontSize: 32,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      : Text(
                                          firstLetter,
                                          style: TextStyle(
                                            color: purpleDeep,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: navy,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      _showEditNameDialog(
                                        context,
                                        name,
                                        authUser.uid,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: subTextColor,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF312E81)
                                    : navy.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _capitalize(rawRole),
                                style: TextStyle(
                                  color: isDark ? Colors.white : navy,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Account Settings',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: sectionTextColor,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: lineColor),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.lock_reset_outlined,
                                color: iconColor,
                              ),
                              title: Text(
                                "Change Password",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: subTextColor,
                              ),
                              onTap: () {
                                _changePassword(context);
                              },
                            ),

                            Divider(height: 1, indent: 50, color: lineColor),

                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: AppTheme.themeMode,
                              builder: (context, themeMode, child) {
                                final isDarkMode = themeMode == ThemeMode.dark;

                                return ListTile(
                                  leading: Icon(
                                    isDarkMode
                                        ? Icons.dark_mode
                                        : Icons.dark_mode_outlined,
                                    color: iconColor,
                                  ),
                                  title: Text(
                                    "Dark Mode",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                  trailing: Switch(
                                    value: isDarkMode,
                                    onChanged: (value) {
                                      AppTheme.toggleTheme(value);
                                    },
                                  ),
                                  onTap: () {
                                    AppTheme.toggleTheme(!isDarkMode);
                                  },
                                );
                              },
                            ),

                            Divider(height: 1, indent: 50, color: lineColor),

                            ListTile(
                              leading: const Icon(
                                Icons.logout_rounded,
                                color: Colors.red,
                              ),
                              title: const Text(
                                "Logout",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              onTap: () {
                                _logout(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
