import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BottomSidebar extends StatelessWidget {
  final int currentIndex;

  const BottomSidebar({super.key, required this.currentIndex});

  static const Color navColor = Color(0xFFD7E3E4);
  static const Color activeColor = Color(0xFF6D718B);

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
    return Container(
      height: 82,
      decoration: const BoxDecoration(
        color: navColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navIcon(context, Icons.home_rounded, 0),
          _navIcon(context, Icons.chat_bubble_rounded, 1),
          _navIcon(context, Icons.add_box_rounded, 2),
          _notificationIcon(context),
          _navIcon(context, Icons.person_rounded, 4),
        ],
      ),
    );
  }

  Widget _notificationIcon(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return _navIcon(context, Icons.notifications_rounded, 3);
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
            _navIcon(context, Icons.notifications_rounded, 3),
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

  Widget _navIcon(BuildContext context, IconData icon, int index) {
    final bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => _goToPage(context, index),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 30,
          color: isActive ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
