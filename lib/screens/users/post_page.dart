import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostPage extends StatelessWidget {
  const PostPage({super.key});

  final Color cardBlue = const Color(0xFFC8D4F0);
  final Color darkText = const Color(0xFF1F223D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Users Collection Test"),
        backgroundColor: cardBlue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text("No user records found"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;

              return Card(
                color: cardBlue,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    data['name'] ?? 'No name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  subtitle: Text(
                    "Email: ${data['email'] ?? '-'}\n"
                        "Role: ${data['role'] ?? '-'}\n"
                        "Course: ${data['course'] ?? '-'}\n"
                        "Skills: ${data['skills'] ?? '-'}",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}