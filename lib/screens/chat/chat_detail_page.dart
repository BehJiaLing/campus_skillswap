import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetailPage extends StatefulWidget {

  final String userName;
  final String chatId;
  final String otherUserId;

  const ChatDetailPage({
    super.key,
    required this.userName,
    required this.chatId,
    required this.otherUserId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {

  final TextEditingController messageController =
  TextEditingController();

  final ScrollController scrollController =
  ScrollController();

  @override
  void initState() {
    super.initState();

    markMessagesAsRead();
  }

  Future<void> markMessagesAsRead() async {

    final currentUserId =
        FirebaseAuth.instance.currentUser!.uid;

    final snapshot =
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .get();

    for (var doc in snapshot.docs) {

      final data = doc.data();

      final List readBy =
          data['readBy'] ?? [];

      if (!readBy.contains(currentUserId)) {

        await doc.reference.update({
          'readBy': FieldValue.arrayUnion([
            currentUserId,
          ]),
        });
      }
    }
  }

  void scrollToBottom() {

    Future.delayed(
      const Duration(milliseconds: 100),

          () {

        if (scrollController.hasClients) {

          scrollController.animateTo(
            scrollController.position.maxScrollExtent,

            duration: const Duration(
              milliseconds: 300,
            ),

            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  Future<void> sendMessage() async {

    if (messageController.text.trim().isEmpty) {
      return;
    }

    String newMessage =
    messageController.text.trim();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': newMessage,
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),

      'readBy': [
        FirebaseAuth.instance.currentUser!.uid,
      ],
    });

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'lastMessage': newMessage,
      'updatedAt':
      FieldValue.serverTimestamp(),
    });

    messageController.clear();

    scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD8ECE6),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF202547),
            size: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFEAEAEA),
              child: Icon(
                Icons.person,
                color: Color(0xFF202547),
              ),
            ),

            const SizedBox(width: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.userName,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.otherUserId)
                      .snapshots(),

                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    final userData =
                    snapshot.data!.data()
                    as Map<String, dynamic>;

                    final isOnline =
                        userData['isOnline'] ?? false;

                    return Text(
                      isOnline
                          ? 'Online'
                          : 'Offline',

                      style: TextStyle(
                        color: isOnline
                            ? Colors.green
                            : Colors.grey,

                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data!.docs;

                scrollToBottom();

                return ListView.builder(
                  controller: scrollController,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),

                  itemCount: messages.length,

                  itemBuilder: (context, index) {

                    final data =
                    messages[index].data() as Map<String, dynamic>;

                    final text = data['text'] ?? '';

                    final senderId =
                        data['senderId'] ?? '';

                    final timestamp =
                    data['createdAt'] as Timestamp?;

                    String timeText = '';

                    if (timestamp != null) {

                      final dateTime =
                      timestamp.toDate();

                      int hour = dateTime.hour;
                      String period = hour >= 12 ? 'PM' : 'AM';

                      hour = hour % 12;
                      if (hour == 0) hour = 12;

                      timeText =
                      '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
                    }

                    final isMe =
                        senderId ==
                            FirebaseAuth.instance.currentUser!.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,

                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 250,
                        ),

                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),

                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),

                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFFF0F0F0)
                                : Colors.white,

                            borderRadius:
                            BorderRadius.circular(18),

                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            mainAxisSize: MainAxisSize.min,

                            children: [

                              Text(
                                text,
                                style: const TextStyle(
                                  fontSize: 15,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Align(
                                alignment: Alignment.bottomRight,

                                child: Text(
                                  timeText,

                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),

            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,

                    onSubmitted: (_) {
                      sendMessage();
                    },

                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Color(0xFF202547),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      sendMessage();
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF202547),
                      foregroundColor: Colors.white,

                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    child: const Text(
                      'Send',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }
}