import '../../../core/storage/secure_storage.dart';
import '../data/auth_api.dart';
import '../data/google_sign_in_service.dart';
import '../domain/user.dart';

class SessionRepository {
  final GoogleSignInService _googleSignInService;
  final AuthApi _authApi;
  final SecureStorage _secureStorage;

  SessionRepository({
    required GoogleSignInService googleSignInService,
    required AuthApi authApi,
    required SecureStorage secureStorage,
  })  : _googleSignInService = googleSignInService,
        _authApi = authApi,
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
}