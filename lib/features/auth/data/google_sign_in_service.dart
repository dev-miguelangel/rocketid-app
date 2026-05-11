import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/config/google_config.dart';

class GoogleSignInServiceException implements Exception {
  final String message;
  GoogleSignInServiceException(this.message);

  @override
  String toString() => message;
}

class GoogleSignInCancelledException extends GoogleSignInServiceException {
  GoogleSignInCancelledException() : super('Google sign in was cancelled');
}

class GoogleSignInService {
  late final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _googleSignIn = GoogleSignIn.instance;
    await _googleSignIn.initialize(
      clientId: GoogleConfig.androidClientId,
      serverClientId: GoogleConfig.serverClientId,
    );
    _initialized = true;
  }

  Future<String> signInAndGetIdToken() async {
    await init();

    try {
      final result = await _googleSignIn.authenticate();
      if (result == null || result.authentication.idToken == null) {
        throw GoogleSignInCancelledException();
      }
      final auth = result.authentication;
      return auth.idToken!;
    } catch (e) {
      if (e is GoogleSignInServiceException) rethrow;
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('cancel') || errorStr.contains('canceled')) {
        throw GoogleSignInCancelledException();
      }
      throw GoogleSignInServiceException(e.toString());
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    await _googleSignIn.signOut();
  }
}