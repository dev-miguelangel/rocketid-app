import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/application/session_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/contacts/contacts_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/auth/domain/user.dart';
import '../features/onboarding/onboarding_alias_screen.dart';
import '../features/onboarding/onboarding_emergency_screen.dart';
import '../features/onboarding/onboarding_medical_screen.dart';
import '../features/onboarding/onboarding_personal_screen.dart';
import '../features/profile/profile_edit_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/splash/splash_screen.dart';
import '../providers.dart';
import 'router_refresh_stream.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final sessionController = ref.watch(sessionControllerProvider.notifier);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(sessionController.stream),
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;

      return switch (session) {
        SessionUnknown() => location == '/splash' ? null : '/splash',
        SessionAuthenticated(:final user) => () {
          final completed =
              user.onboardingStep != null && user.onboardingStep != 0;
          final inOnboarding = location.startsWith('/onboarding/');
          if (completed) {
            final inAuthFlow =
                location == '/login' ||
                location == '/splash' ||
                inOnboarding;
            return inAuthFlow ? '/inicio' : null;
          }
          return inOnboarding ? null : '/onboarding/alias';
        }(),
        SessionUnauthenticated() when location == '/login' => null,
        _ => '/login',
      };
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/onboarding/alias',
        builder: (context, state) => const OnboardingAliasScreen(),
      ),
      GoRoute(
        path: '/onboarding/personal',
        builder: (context, state) => const OnboardingPersonalScreen(),
      ),
      GoRoute(
        path: '/onboarding/medical',
        builder: (context, state) => const OnboardingMedicalScreen(),
      ),
      GoRoute(
        path: '/onboarding/emergency',
        builder: (context, state) => const OnboardingEmergencyScreen(),
      ),
      GoRoute(
        path: '/inicio',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/contactos',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          final initialTab = switch (tab) {
            'grupos' => 1,
            'equipos' => 2,
            _ => 0,
          };
          return ContactsScreen(initialTab: initialTab);
        },
      ),
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'editar/personal',
            builder: (context, state) => ProfileEditScreen(
              user: state.extra! as User,
              section: ProfileEditSection.personal,
            ),
          ),
          GoRoute(
            path: 'editar/medica',
            builder: (context, state) => ProfileEditScreen(
              user: state.extra! as User,
              section: ProfileEditSection.medical,
            ),
          ),
          GoRoute(
            path: 'editar/emergencia',
            builder: (context, state) => ProfileEditScreen(
              user: state.extra! as User,
              section: ProfileEditSection.emergency,
            ),
          ),
        ],
      ),
    ],
  );
});
