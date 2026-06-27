import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../profile/presentation/views/user_profile_dialog.dart';

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
  static const navy = Color(0xFF102A72);
  static const green = Color(0xFF12A875);
  final TextEditingController messageController = TextEditingController();

  final ScrollController scrollController = ScrollController();
  bool isSending = false;

  @override
  void initState() {
    super.initState();

    markMessagesAsRead();
  }

  Future<void> markMessagesAsRead() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final List readBy = data['readBy'] ?? [];

      if (!readBy.contains(currentUserId)) {
        await doc.reference.update({
          'readBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    }

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set(
      {
        'unreadFor': {currentUserId: 0},
      },
      SetOptions(merge: true),
    );

    final notifications = await FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUserId)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final notification in notifications.docs) {
      final data = notification.data();
      if (data['type'] == 'chat_message' &&
          data['chatId'] == widget.chatId &&
          data['isRead'] != true) {
        batch.update(notification.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,

          duration: const Duration(milliseconds: 300),

          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty || isSending) {
      return;
    }

    setState(() => isSending = true);

    String newMessage = messageController.text.trim();
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
            'text': newMessage,
            'senderId': FirebaseAuth.instance.currentUser!.uid,
            'createdAt': FieldValue.serverTimestamp(),

            'readBy': [FirebaseAuth.instance.currentUser!.uid],
          });

      final senderId = FirebaseAuth.instance.currentUser!.uid;
      final sender = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': widget.otherUserId,
        'senderId': senderId,
        'senderName': sender.data()?['name'] ?? 'A student',
        'type': 'chat_message',
        'chatId': widget.chatId,
        'postId': '',
        'postTitle': 'New message',
        'message': newMessage,
        'status': 'info',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
            'lastMessage': newMessage,
            'updatedAt': FieldValue.serverTimestamp(),
            'unreadFor.${widget.otherUserId}': FieldValue.increment(1),
          });

      messageController.clear();
      scrollToBottom();
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111827)
          : const Color(0xFFF4F7FB),

      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () =>
                  showUserProfileDialog(context, userId: widget.otherUserId),
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_rounded, color: navy),
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
                    color: Colors.white,
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
                        snapshot.data!.data() as Map<String, dynamic>;

                    final isOnline = userData['isOnline'] ?? false;

                    return Text(
                      isOnline ? 'Online' : 'Offline',

                      style: TextStyle(
                        color: isOnline
                            ? const Color(0xFF75E6BA)
                            : Colors.white70,

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
                  return const Center(child: CircularProgressIndicator());
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
                    final data = messages[index].data() as Map<String, dynamic>;

                    final text = data['text'] ?? '';

                    final senderId = data['senderId'] ?? '';

                    final timestamp = data['createdAt'] as Timestamp?;

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

                    final isMe =
                        senderId == FirebaseAuth.instance.currentUser!.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,

                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),

                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),

                          margin: const EdgeInsets.only(bottom: 12),

                          decoration: BoxDecoration(
                            color: isMe ? navy : surface,

                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMe ? 18 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 18),
                            ),

                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            mainAxisSize: MainAxisSize.min,

                            children: [
                              Text(
                                text,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isMe ? Colors.white : onSurface,
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
            margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .08),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),

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
                      fillColor: isDark
                          ? const Color(0xFF273449)
                          : const Color(0xFFF5F5F5),

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
                        borderSide: const BorderSide(color: Color(0xFF202547)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                IconButton.filled(
                  onPressed: isSending ? null : sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: green.withValues(alpha: .5),
                  ),
                  icon: isSending
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
