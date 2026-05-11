import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/application/session_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/welcome/welcome_screen.dart';
import '../providers.dart';
import 'router_refresh_stream.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final sessionController = ref.watch(sessionControllerProvider.notifier);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      sessionController.stream,
    ),
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;

      return switch (session) {
        SessionUnknown() => location == '/splash' ? null : '/splash',
        SessionAuthenticated() when location == '/login' || location == '/splash' =>
          '/welcome',
        SessionAuthenticated() => null,
        SessionUnauthenticated() when location == '/login' => null,
        _ => '/login',
      };
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/inicio',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});