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
import '../features/welcome/welcome_screen.dart';
import '../providers.dart';
import 'router_refresh_stream.dart';

String? _onboardingTarget(int? step) => switch (step ?? 0) {
      0 => '/welcome',
      1 => '/onboarding/alias',
      2 => '/onboarding/personal',
      3 => '/onboarding/medical',
      4 => '/onboarding/emergency',
      _ => null, // >= 5 → onboarding completado
    };

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
        SessionAuthenticated(:final user) => () {
            final target = _onboardingTarget(user.onboardingStep);
            if (target == null) {
              // Onboarding terminado: sacarlo del flujo de auth/onboarding.
              final inAuthFlow = location == '/login' ||
                  location == '/splash' ||
                  location == '/welcome' ||
                  location.startsWith('/onboarding/');
              return inAuthFlow ? '/inicio' : null;
            }
            // Onboarding pendiente: forzar el paso correspondiente.
            return location == target ? null : target;
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
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
        builder: (context, state) => const ContactsScreen(),
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