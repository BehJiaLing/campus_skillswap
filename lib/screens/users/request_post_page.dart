import 'package:flutter/material.dart';
import '../../widgets/bottom_sidebar.dart';

class RequestPostPage extends StatelessWidget {
  const RequestPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Request Post Updates",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: BottomSidebar(currentIndex: 3),
    );
  }
}