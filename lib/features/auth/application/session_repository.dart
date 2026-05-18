import 'dart:developer' as developer;
import '../../../core/storage/secure_storage.dart';
import '../data/auth_api.dart';
import '../data/google_sign_in_service.dart';
import '../data/users_api.dart';
import '../domain/user.dart';

class SessionRepository {
  final GoogleSignInService _googleSignInService;
  final AuthApi _authApi;
  final UsersApi _usersApi;
  final SecureStorage _secureStorage;

  SessionRepository({
    required GoogleSignInService googleSignInService,
    required AuthApi authApi,
    required UsersApi usersApi,
    required SecureStorage secureStorage,
  })  : _googleSignInService = googleSignInService,
        _authApi = authApi,
        _usersApi = usersApi,
        _secureStorage = secureStorage;

  Future<User?> bootstrap() async {
    final userJson = await _secureStorage.user;
    final accessToken = await _secureStorage.accessToken;
    final refreshToken = await _secureStorage.refreshToken;

    if (userJson != null && accessToken != null && refreshToken != null) {
      try {
        final user = await _authApi.me();
        return user;
      } catch (_) {
        await _secureStorage.clearAll();
        return null;
      }
    }
    return null;
  }

  Future<User> loginWithGoogle() async {
    final idToken = await _googleSignInService.signInAndGetIdToken();
    final authResponse = await _authApi.loginWithGoogleIdToken(idToken);

    await _secureStorage.setAccessToken(authResponse.accessToken);
    await _secureStorage.setRefreshToken(authResponse.refreshToken);
    await _secureStorage.setUser(authResponse.user.toJson());

    return authResponse.user;
  }

  Future<void> logout() async {
    await _googleSignInService.signOut();
    await _secureStorage.clearAll();
  }

  Future<User> setOnboardingStep(int step, User current) async {
    developer.log('setOnboardingStep called with step: $step, current step: ${current.onboardingStep}');
    final newStep = await _usersApi.updateOnboardingStep(step);
    developer.log('API returned newStep: $newStep');
    final merged = current.copyWith(onboardingStep: newStep);
    await _secureStorage.setUser(merged.toJson());
    return merged;
  }
}