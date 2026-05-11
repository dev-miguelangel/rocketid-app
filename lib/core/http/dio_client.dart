import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/google_config.dart';
import 'auth_interceptor.dart';
import '../storage/secure_storage.dart';

class DioClient {
  static Dio createDio({
    required SecureStorage secureStorage,
    required Future<void> Function() onAuthFailure,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AuthBackendConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: AuthBackendConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final authInterceptor = AuthInterceptor(
      storage: secureStorage,
      refreshDio: refreshDio,
      onAuthFailure: onAuthFailure,
    );

    dio.interceptors.add(authInterceptor);

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
      );
    }

    return dio;
  }
}