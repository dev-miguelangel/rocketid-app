import 'package:dio/dio.dart';
import '../../../core/config/google_config.dart';
import '../domain/auth_response.dart';
import '../domain/user.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<AuthResponse> loginWithGoogleIdToken(String idToken) async {
    final response = await _dio.post(
      AuthBackendConfig.googleTokenPath,
      data: {'idToken': idToken},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RefreshResponse> refresh(String refreshToken) async {
    final response = await _dio.post(
      AuthBackendConfig.refreshTokenPath,
      data: {'refreshToken': refreshToken},
    );
    return RefreshResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> me() async {
    final response = await _dio.get(AuthBackendConfig.mePath);
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}