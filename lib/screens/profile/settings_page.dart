import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> changePassword(
      BuildContext context) async {

    final email =
        FirebaseAuth.instance.currentUser?.email;

    if (email == null) return;

    await FirebaseAuth.instance
        .sendPasswordResetEmail(
      email: email,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Password reset email sent",
        ),
      ),
    );
  }

  Future<void> logout(
      BuildContext context) async {

    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'isOnline': false,
    });

    await FirebaseAuth.instance.signOut();

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF8F8F8),

      appBar: AppBar(
        title: const Text(
          "Settings",
        ),
      ),

      body: Padding(
        padding:
        const EdgeInsets.all(20),

        child: Column(
          children: [

            Container(
              decoration: BoxDecoration(
                color:
                const Color(0xFFF1F1E8),

                borderRadius:
                BorderRadius.circular(20),
              ),

              child: Column(
                children: [

                  ListTile(
                    leading:
                    const Icon(
                      Icons.lock_reset,
                    ),

                    title:
                    const Text(
                      "Change Password",
                    ),

                    trailing:
                    const Icon(
                      Icons.chevron_right,
                    ),

                    onTap: () {
                      changePassword(
                          context);
                    },
                  ),

                  const Divider(),

                  ListTile(
                    leading:
                    const Icon(
                      Icons.dark_mode,
                    ),

                    title:
                    const Text(
                      "Dark Mode",
                    ),

                    trailing:
                    const Icon(
                      Icons.chevron_right,
                    ),

                    onTap: () {},
                  ),

                  const Divider(),

                  ListTile(
                    leading:
                    const Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),

                    title:
                    const Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),

                    onTap: () {
                      logout(context);
                    },
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