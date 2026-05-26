import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/create_profile_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/conversation_screen.dart';
import '../../features/schedule/screens/schedule_screen.dart';
import '../../features/schedule/screens/my_requests_screen.dart';
import '../../features/sessions/screens/sessions_screen.dart';
import '../../features/call/screens/pre_join_screen.dart';
import '../../features/call/screens/call_screen.dart';
import '../../features/call/screens/post_call_rating_screen.dart';

final guruRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/create-profile',
        builder: (_, __) => const CreateProfileScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
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
        path: '/schedule',
        builder: (_, __) => const ScheduleScreen(),
      ),
      GoRoute(
        path: '/requests',
        builder: (_, __) => const MyRequestsScreen(),
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
        builder: (_, state) => PostCallRatingScreen(
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
    final done = await AuthService.instance.isOnboardingDone();
    if (!mounted) return;
    if (done) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
