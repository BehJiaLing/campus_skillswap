import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  final Color navy = const Color(0xFF1A1F5E);
  final Color bg = const Color(0xFFF5F5FA);
  final Color border = const Color(0xFFE0E0F0);
  final Color purple = const Color(0xFFE8E4F8);
  final Color purpleDeep = const Color(0xFF7C5CBF);

  String _getText(Map<String, dynamic> data, List<String> keys, String fallback) {
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

  // Action function to send password reset email (mirrors student settings)
  Future<void> _changePassword(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password reset email sent successfully")),
    );
  }

  // Clear online flag and sign out session
  Future<void> _logout(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isOnline': false,
      });
    }
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // Pops up a stylized dialog to modify the name document entry safely
  void _showEditNameDialog(BuildContext context, String currentName, String uid) {
    final TextEditingController nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Admin Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'name': newName,
                  'fullName': newName, // Keeps fallback keys synchronized
                });
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bg,
      //drawer: const AdminDrawer(),//
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
      body: authUser == null
          ? const Center(child: Text('No active administrative session.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(authUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() ?? {};
          final name = _getText(data, ['name', 'fullName'], 'Admin User');
          final rawRole = _getText(data, ['role'], 'admin');
          final email = authUser.email ?? _getText(data, ['email'], 'admin@email.com');
          final profileImageUrl = _getText(data, ['profileImageUrl', 'photoUrl'], '');
          final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- PROFILE CARD HEADER SECTION ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
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
                            backgroundColor: purple,
                            child: profileImageUrl.isNotEmpty
                                ? ClipOval(
                              child: Image.network(
                                profileImageUrl,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            )
                                : Text(
                              firstLetter,
                              style: TextStyle(color: purpleDeep, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: navy,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                              onPressed: () => _showEditNameDialog(context, name, authUser.uid),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      // Administrative Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: navy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _capitalize(rawRole),
                          style: TextStyle(color: navy, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Account Settings',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                const SizedBox(height: 10),

                // --- CONFIGURATION LIST TILES SECTION ---
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.lock_reset_outlined, color: navy),
                        title: const Text("Change Password", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => _changePassword(context),
                      ),
                      const Divider(height: 1, indent: 50),
                      ListTile(
                        leading: Icon(Icons.dark_mode_outlined, color: navy),
                        title: const Text("Dark Mode", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {}, // Handled identically to your existing dashboard file
                      ),
                      const Divider(height: 1, indent: 50),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: Colors.red),
                        title: const Text("Logout", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                        onTap: () => _logout(context),
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