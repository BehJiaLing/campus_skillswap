import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'screens/auth/login_page.dart';
import 'screens/auth/signup_page.dart';
import 'screens/auth/create_profile_page.dart';
import 'screens/auth/forgot_password_page.dart';

import 'screens/users/post_page.dart';

import 'screens/admin/admin_dashboard_page.dart';
import 'screens/admin/admin_user_management_page.dart';
import 'screens/admin/admin_user_management_dashboard.dart';
import 'screens/admin/admin_post_manage_page.dart';
import 'screens/chat/chat_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
       initialRoute: '/login',
      //home: const ChatListPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/create-profile': (context) => const CreateProfilePage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),

        '/post': (context) => const PostPage(),

        '/chat': (context) => const ChatListPage(),

        '/admin/dashboard': (context) => const AdminDashboardPage(),
        '/admin/user-management': (context) => const UserManagementPage(),
        '/admin/users': (context) => const AdminUsersPage(),

        '/admin/post-management': (context) => const AdminPostManagementPage(),
      },
    );
  }
}