import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BottomSidebar extends StatelessWidget {
  final int currentIndex;

  const BottomSidebar({super.key, required this.currentIndex});

  static const Color navy = Color(0xFF102A72);
  static const Color green = Color(0xFF12A875);

  void _goToPage(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/post');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/chat');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/create-post');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/request-post');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172033) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navIcon(context, Icons.home_rounded, 'Posts', 0),
              _chatIcon(context),
              _navIcon(context, Icons.add_rounded, 'Create', 2),
              _notificationIcon(context),
              _navIcon(context, Icons.person_rounded, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationIcon(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return _navIcon(context, Icons.notifications_rounded, 'Alerts', 3);
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        final unread =
            snapshot.data?.docs.any(
              (document) => document.data()['isRead'] != true,
            ) ==
            true;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _navIcon(context, Icons.notifications_rounded, 'Alerts', 3),
            if (unread)
              const Positioned(
                right: 3,
                top: 2,
                child: CircleAvatar(radius: 6, backgroundColor: Colors.red),
              ),
          ],
        );
      },
    );
  }

  Widget _chatIcon(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return _navIcon(context, Icons.chat_bubble_rounded, 'Chats', 1);
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('userIDs', arrayContains: userId)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCounter =
            snapshot.data?.docs.any((document) {
              final map = document.data()['unreadFor'];
              return map is Map && ((map[userId] as num?)?.toInt() ?? 0) > 0;
            }) ==
            true;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('recipientId', isEqualTo: userId)
              .snapshots(),
          builder: (context, notificationSnapshot) {
            final unreadMessage =
                notificationSnapshot.data?.docs.any((document) {
                  final data = document.data();
                  return data['type'] == 'chat_message' &&
                      data['isRead'] != true;
                }) ==
                true;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _navIcon(context, Icons.chat_bubble_rounded, 'Chats', 1),
                if (unreadCounter || unreadMessage)
                  const Positioned(
                    right: 3,
                    top: 2,
                    child: CircleAvatar(radius: 6, backgroundColor: Colors.red),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _navIcon(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => _goToPage(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 66,
        height: 52,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? green.withValues(alpha: .13) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive
                  ? green
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? green
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
