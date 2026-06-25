import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'app_theme.dart';

import 'screens/auth/login_page.dart';
import 'screens/auth/signup_page.dart';
import 'screens/auth/create_profile_page.dart';
import 'screens/auth/forgot_password_page.dart';

import 'screens/users/post_page.dart';
import 'screens/users/create_post_page.dart';
import 'screens/users/request_post_page.dart';

import 'screens/admin/admin_dashboard_page.dart';
import 'screens/admin/admin_user_management_page.dart';
import 'screens/admin/admin_user_management_dashboard.dart';
import 'screens/admin/admin_post_manage_page.dart';
import 'screens/admin/admin_settings_page.dart';
import 'screens/admin/admin_user_access.dart';

import 'screens/chat/chat_list_page.dart';
import 'screens/profile/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AppTheme.loadTheme();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color darkText = Color(0xFF1F223D);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Campus SkillSwap',
          debugShowCheckedModeBanner: false,

          themeMode: themeMode,

          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFC8D4F0),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1F5E),
              foregroundColor: Colors.white,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(
                color: darkText,
              ),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(14),
                ),
              ),
            ),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF111827),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A1F5E),
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF111827),
              foregroundColor: Colors.white,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1F2937),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(14),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1F2937),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          home: const AuthGate(),

          routes: {
            // Auth pages always light mode
            '/login': (context) => const LightThemeWrapper(
              child: LoginPage(),
            ),
            '/signup': (context) => const LightThemeWrapper(
              child: SignUpPage(),
            ),
            '/create-profile': (context) => const LightThemeWrapper(
              child: CreateProfilePage(),
            ),
            '/forgot-password': (context) => const LightThemeWrapper(
              child: ForgotPasswordPage(),
            ),

            // User
            '/post': (context) => const PostPage(),
            '/create-post': (context) => CreatePostPage(),
            '/request-post': (context) => const RequestPostPage(),
            '/chat': (context) => const ChatListPage(),
            '/profile': (context) => const ProfilePage(),

            // Admin
            '/admin/dashboard': (context) => const AdminDashboardPage(),
            '/admin/user-management': (context) => const UserManagementPage(),
            '/admin/users': (context) => const AdminUsersPage(),
            '/admin/post-management': (context) =>
            const AdminPostManagementPage(),
            '/admin/settings': (context) => const AdminSettingsPage(),
            '/admin/user-access': (context) => const AdminUserAccessPage(),
          },

          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const LightThemeWrapper(
                child: LoginPage(),
              ),
            );
          },
        );
      },
    );
  }
}

class LightThemeWrapper extends StatelessWidget {
  final Widget child;

  const LightThemeWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8D4F0),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1F5E),
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Color(0xFF1F223D),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(
            color: Color(0xFF6B6B8A),
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF6B6B8A),
          ),
          prefixIconColor: const Color(0xFF1A1F5E),
          suffixIconColor: const Color(0xFF6B6B8A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE0E0F0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF1A1F5E),
              width: 1.4,
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String> getStartRoute() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return '/login';
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();

      if (data == null) {
        return '/create-profile';
      }

      final isSuspended = data['suspended'] == true || data['banned'] == true;

      if (isSuspended) {
        await FirebaseAuth.instance.signOut();
        return '/login';
      }

      final role = data['role']?.toString().trim().toLowerCase() ?? 'user';

      if (role == 'admin' || role == 'superadmin') {
        return '/admin/dashboard';
      }

      return '/post';
    } catch (e) {
      return '/login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getStartRoute(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const LightThemeWrapper(
            child: LoginPage(),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(
            context,
            snapshot.data!,
          );
        });

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}