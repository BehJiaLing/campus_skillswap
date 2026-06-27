import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'app/app_dependencies.dart';
import 'features/posts/presentation/view_models/create_post_view_model.dart';
import 'features/posts/presentation/view_models/my_requests_view_model.dart';
import 'features/posts/presentation/view_models/post_feed_view_model.dart';
import 'features/posts/presentation/view_models/request_post_detail_view_model.dart';
import 'features/auth/presentation/view_models/startup_view_model.dart';

import 'features/auth/presentation/views/login_page.dart';
import 'features/auth/presentation/views/signup_page.dart';
import 'features/auth/presentation/views/create_profile_page.dart';
import 'features/auth/presentation/views/forgot_password_page.dart';
import 'features/auth/presentation/views/verify_email_page.dart';

import 'features/posts/presentation/views/post_page.dart';
import 'features/posts/presentation/views/create_post_page.dart';
import 'features/posts/presentation/views/request_post_page.dart';

import 'features/admin/presentation/views/admin_dashboard_page.dart';
import 'features/admin/presentation/views/admin_user_management_page.dart';
import 'features/admin/presentation/views/admin_user_management_dashboard.dart';
import 'features/admin/presentation/views/admin_post_manage_page.dart';
import 'features/admin/presentation/views/admin_settings_page.dart';
import 'features/admin/presentation/views/admin_user_access.dart';

import 'features/chat/presentation/views/chat_list_page.dart';
import 'features/profile/presentation/views/profile_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  AppDependencies? _dependencies;
  Object? _startupError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _startupError = null;
    });

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (!mounted) return;
      setState(() {
        _dependencies = AppDependencies.firebase();
      });

      unawaited(
        AppTheme.loadTheme().onError((error, stackTrace) {
          // The light theme remains a safe fallback if preferences fail.
        }),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _startupError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = _dependencies;
    if (dependencies != null) {
      return MyApp(dependencies: dependencies);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: _startupError == null
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Campus SkillSwap could not start.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initialize,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

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
            textTheme: const TextTheme(bodyMedium: TextStyle(color: darkText)),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
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
                borderRadius: BorderRadius.all(Radius.circular(14)),
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

          home: AuthGate(
            viewModel: StartupViewModel(
              dependencies.authRepository,
              dependencies.userProfileRepository,
            ),
          ),

          routes: {
            // Auth pages always light mode
            '/login': (context) => const LightThemeWrapper(child: LoginPage()),
            '/signup': (context) =>
                const LightThemeWrapper(child: SignUpPage()),
            '/verify-email': (context) =>
                const LightThemeWrapper(child: VerifyEmailPage()),
            '/create-profile': (context) =>
                const LightThemeWrapper(child: CreateProfilePage()),
            '/forgot-password': (context) =>
                const LightThemeWrapper(child: ForgotPasswordPage()),

            // User
            '/post': (context) => PostPage(
              viewModel: PostFeedViewModel(dependencies.postRepository),
              detailViewModelBuilder: (postId) => RequestPostDetailViewModel(
                dependencies.postRepository,
                dependencies.authRepository,
                dependencies.userProfileRepository,
                postId,
              ),
            ),
            '/create-post': (context) => CreatePostPage(
              viewModel: CreatePostViewModel(
                dependencies.postRepository,
                dependencies.userProfileRepository,
                dependencies.authRepository,
              ),
            ),
            '/request-post': (context) => RequestPostPage(
              viewModel: MyRequestsViewModel(
                dependencies.postRepository,
                dependencies.authRepository,
              ),
              detailViewModelBuilder: (postId) => RequestPostDetailViewModel(
                dependencies.postRepository,
                dependencies.authRepository,
                dependencies.userProfileRepository,
                postId,
              ),
            ),
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
              builder: (context) => const LightThemeWrapper(child: LoginPage()),
            );
          },
        );
      },
    );
  }
}

class LightThemeWrapper extends StatelessWidget {
  final Widget child;

  const LightThemeWrapper({super.key, required this.child});

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
          bodyMedium: TextStyle(color: Color(0xFF1F223D)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: Color(0xFF6B6B8A)),
          labelStyle: const TextStyle(color: Color(0xFF6B6B8A)),
          prefixIconColor: const Color(0xFF1A1F5E),
          suffixIconColor: const Color(0xFF6B6B8A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A1F5E), width: 1.4),
          ),
        ),
      ),
      child: child,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.viewModel});

  final StartupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: viewModel.resolveStartRoute(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const LightThemeWrapper(child: LoginPage());
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, snapshot.data!);
        });

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
