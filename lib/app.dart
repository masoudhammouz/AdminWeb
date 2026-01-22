import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/theme.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/categories_page.dart';
import 'pages/users_page.dart';
import 'pages/community_page.dart';
import 'pages/chat_page.dart';
import 'pages/words_page.dart';
import 'pages/notifications_page.dart';
import 'pages/letter_sounds_page.dart';
import 'pages/journey_page.dart';
import 'pages/category_form_page.dart';
import 'pages/word_form_page.dart';
import 'pages/letter_sound_form_page.dart';
import 'pages/journey_question_form_page.dart';
import 'providers/auth_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Admin Panel',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/dashboard': (_) => const DashboardPage(),
          '/categories': (_) => const CategoriesPage(),
          '/users': (_) => const UsersPage(),
          '/community': (_) => const CommunityPage(),
          '/chat': (_) => const ChatPage(),
          '/words': (_) => const WordsPage(),
          '/notifications': (_) => const NotificationsPage(),
          '/letter-sounds': (_) => const LetterSoundsPage(),
          '/journey': (_) => const JourneyPage(),
          '/category-form': (_) => const CategoryFormPage(),
          '/word-form': (_) => const WordFormPage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isAuth = await AuthService.isAuthenticated();
    setState(() {
      _isAuthenticated = isAuth;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: AppColors.beige,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthenticated) {
      return const LoginPage();
    }

    return const DashboardPage();
  }
}
