import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_page.dart';
import '../../widgets/bottom_sidebar.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() =>
      _ChatListPageState();
}

class _ChatListPageState
    extends State<ChatListPage> {

  String searchText = '';

  Future<void> deleteChat(
      String chatId,
      ) async {

    final messages =
    await FirebaseFirestore.instance
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

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid;

    print("LOGIN USER UID = $currentUserId");

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not logged in'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Chat History"),
      ),

      body: Column(
        children: [

          Container(
            padding: const EdgeInsets.all(12),

            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search user...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              onChanged: (value) {
                setState(() {
                  searchText =
                      value.toLowerCase().trim();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .orderBy(
                'updatedAt',
                descending: true,
              )
                  .snapshots(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final chats = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: chats.length,

                  itemBuilder: (context, index) {

                    final chat =
                    chats[index].data()
                    as Map<String, dynamic>;

                    final timestamp =
                    chat['updatedAt'] as Timestamp?;

                    String timeText = '';

                    if (timestamp != null) {

                      final dateTime =
                      timestamp.toDate();

                      int hour = dateTime.hour;
                      String period =
                      hour >= 12 ? 'PM' : 'AM';

                      hour = hour % 12;
                      if (hour == 0) hour = 12;

                      timeText =
                      '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
                    }

                    final List userIDs =
                        chat['userIDs'] ?? [];

                    if (!userIDs.contains(currentUserId)) {
                      return const SizedBox();
                    }

                    final otherUserId =
                    userIDs.firstWhere(
                          (id) => id != currentUserId,
                    );

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .where(
                        FieldPath.documentId,
                        isEqualTo: otherUserId,
                      )
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

                        final userName =
                            userData['name'] ??
                                'Unknown User';

                        if (searchText.isNotEmpty &&
                            !userName
                                .toLowerCase()
                                .contains(searchText)) {
                          return const SizedBox();
                        }

                        final isOnline =
                            userData['isOnline'] ?? false;

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

                              for (var doc
                              in msgSnapshot.data!.docs) {

                                final data =
                                doc.data()
                                as Map<String, dynamic>;

                                final senderId =
                                data['senderId'];

                                final List readBy =
                                    data['readBy'] ?? [];

                                if (senderId != currentUid &&
                                    !readBy.contains(
                                        currentUid)) {
                                  unreadCount++;
                                }
                              }
                            }

                            return Card(
                              margin:
                              const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),

                              elevation: 2,

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    15),
                              ),

                              child: ListTile(
                                contentPadding:
                                const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),

                                leading:
                                const CircleAvatar(
                                  radius: 25,
                                  backgroundColor:
                                  Color(0xFFD8ECE6),
                                  child: Icon(
                                    Icons.person,
                                    color:
                                    Color(0xFF202547),
                                  ),
                                ),

                                title: Text(
                                  userName,
                                  style:
                                  const TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),

                                subtitle: Text(
                                  chat['lastMessage'] ?? '',
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                ),

                                trailing: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [

                                    Text(
                                      timeText,
                                      style:
                                      const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    if (unreadCount > 0)

                                      Container(
                                        padding:
                                        const EdgeInsets.all(
                                            6),

                                        decoration:
                                        const BoxDecoration(
                                          color: Colors.red,
                                          shape:
                                          BoxShape.circle,
                                        ),

                                        child: Text(
                                          unreadCount
                                              .toString(),
                                          style:
                                          const TextStyle(
                                            color:
                                            Colors.white,
                                            fontSize: 10,
                                            fontWeight:
                                            FontWeight.bold,
                                          ),
                                        ),
                                      )

                                    else

                                      Text(
                                        isOnline
                                            ? 'Online'
                                            : 'Offline',

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
                                      builder: (_) =>
                                          ChatDetailPage(
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
      bottomNavigationBar: const BottomSidebar(currentIndex: 1),
    );

  }
}