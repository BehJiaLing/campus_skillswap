// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
//
// // import 'firebase_options.dart';
// import 'screens/auth/login_page.dart';
// import 'screens/users/post_page.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Firebase.initializeApp();
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   static const Color darkText = Color(0xFF1F223D);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Campus SkillSwap',
//       debugShowCheckedModeBanner: false,
//
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: Colors.white,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFFC8D4F0),
//         ),
//       ),
//
//       home: const LoginPage(),
//
//       routes: {
//         '/login': (context) => const LoginPage(),
//         '/post': (context) => const PostPage(),
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// import 'firebase_options.dart';
import 'screens/users/post_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color darkText = Color(0xFF1F223D);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus SkillSwap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8D4F0),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: darkText),
        ),
      ),

      home: const PostPage(),
    );
  }
}