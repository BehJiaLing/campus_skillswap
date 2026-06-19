import 'package:flutter/material.dart';
import '../../widgets/bottom_sidebar.dart';

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Create Post",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: BottomSidebar(currentIndex: 2),
    );
  }
}