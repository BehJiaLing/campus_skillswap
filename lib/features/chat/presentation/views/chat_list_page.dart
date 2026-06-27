import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_page.dart';
import '../../../../core/widgets/bottom_sidebar.dart';
import '../../../../core/widgets/skill_swap_page_header.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  String searchText = '';

  Future<void> deleteChat(String chatId) async {
    final messages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    for (var doc in messages.docs) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(doc.id)
          .delete();
    }

    await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            const SkillSwapPageHeader(
              title: 'Messages',
              subtitle: 'Continue conversations with your matched partners.',
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(18, 4, 18, 8),
              padding: const EdgeInsets.symmetric(horizontal: 4),

              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search conversations',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF102A72),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),

                onChanged: (value) {
                  setState(() {
                    searchText = value.toLowerCase().trim();
                  });
                },
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .orderBy('updatedAt', descending: true)
                    .snapshots(),

                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final chats = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: chats.length,

                    itemBuilder: (context, index) {
                      final chat = chats[index].data() as Map<String, dynamic>;

                      final timestamp = chat['updatedAt'] as Timestamp?;

                      String timeText = '';

                      if (timestamp != null) {
                        final dateTime = timestamp.toDate();

                        int hour = dateTime.hour;
                        String period = hour >= 12 ? 'PM' : 'AM';

                        hour = hour % 12;
                        if (hour == 0) hour = 12;

                        timeText =
                            '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
                      }

                      final List userIDs = chat['userIDs'] ?? [];

                      if (!userIDs.contains(currentUserId)) {
                        return const SizedBox();
                      }

                      final otherUserId = userIDs.firstWhere(
                        (id) => id != currentUserId,
                      );

                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .where(FieldPath.documentId, isEqualTo: otherUserId)
                            .get(),

                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return const SizedBox();
                          }

                          if (userSnapshot.data!.docs.isEmpty) {
                            return const SizedBox();
                          }

                          final userData =
                              userSnapshot.data!.docs.first.data()
                                  as Map<String, dynamic>;

                          final userName = userData['name'] ?? 'Unknown User';

                          if (searchText.isNotEmpty &&
                              !userName.toLowerCase().contains(searchText)) {
                            return const SizedBox();
                          }

                          final isOnline = userData['isOnline'] ?? false;

                          final currentUid =
                              FirebaseAuth.instance.currentUser!.uid;

                          return FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('chats')
                                .doc(chats[index].id)
                                .collection('messages')
                                .get(),

                            builder: (context, msgSnapshot) {
                              int unreadCount = 0;

                              if (msgSnapshot.hasData) {
                                for (var doc in msgSnapshot.data!.docs) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;

                                  final senderId = data['senderId'];

                                  final List readBy = data['readBy'] ?? [];

                                  if (senderId != currentUid &&
                                      !readBy.contains(currentUid)) {
                                    unreadCount++;
                                  }
                                }
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 7,
                                ),

                                elevation: 0,
                                color: Theme.of(context).colorScheme.surface,

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withValues(alpha: .6),
                                  ),
                                ),

                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),

                                  leading: const CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Color(0xFFE8EEFF),
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: Color(0xFF102A72),
                                    ),
                                  ),

                                  title: Text(
                                    userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  subtitle: Text(
                                    chat['lastMessage'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        timeText,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      if (unreadCount > 0)
                                        Container(
                                          padding: const EdgeInsets.all(6),

                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),

                                          child: Text(
                                            unreadCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      else
                                        Text(
                                          isOnline ? 'Online' : 'Offline',

                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isOnline
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),

                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatDetailPage(
                                          userName: userName,
                                          chatId: chats[index].id,
                                          otherUserId: otherUserId,
                                        ),
                                      ),
                                    );
                                  },

                                  onLongPress: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Delete Chat'),
                                          content: const Text(
                                            'Are you sure you want to delete this chat?',
                                          ),

                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Cancel'),
                                            ),

                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(context);

                                                await deleteChat(
                                                  chats[index].id,
                                                );
                                              },
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomSidebar(currentIndex: 1),
    );
  }
}
