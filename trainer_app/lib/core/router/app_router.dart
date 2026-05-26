import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/members/screens/members_list_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/conversation_screen.dart';
import '../../features/requests/screens/requests_screen.dart';
import '../../features/sessions/screens/sessions_screen.dart';
import '../../features/call/screens/pre_join_screen.dart';
import '../../features/call/screens/call_screen.dart';
import '../../features/call/screens/post_call_notes_screen.dart';

final trainerRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/members',
        builder: (_, __) => const MembersListScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (_, __) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder: (_, state) =>
            ConversationScreen(chatId: state.pathParameters['chatId']!),
      ),
      GoRoute(
        path: '/requests',
        builder: (_, __) => const RequestsScreen(),
      ),
      GoRoute(
        path: '/sessions',
        builder: (_, __) => const SessionsScreen(),
      ),
      GoRoute(
        path: '/pre-join/:callRequestId',
        builder: (_, state) => PreJoinScreen(
            callRequestId: state.pathParameters['callRequestId']!),
      ),
      GoRoute(
        path: '/call/:callRequestId',
        builder: (_, state) =>
            CallScreen(callRequestId: state.pathParameters['callRequestId']!),
      ),
      GoRoute(
        path: '/post-call/:sessionLogId',
        builder: (_, state) => PostCallNotesScreen(
            sessionLogId: state.pathParameters['sessionLogId']!),
      ),
    ],
  );
});

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!mounted) return;
    context.go(loggedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
