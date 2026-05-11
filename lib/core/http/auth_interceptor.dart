import 'dart:async';
import 'package:dio/dio.dart';
import '../config/google_config.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorage _storage;
  final Dio _refreshDio;
  final Future<void> Function() _onAuthFailure;
  Completer<void>? _refreshing;

  AuthInterceptor({
    required SecureStorage storage,
    required Dio refreshDio,
    required Future<void> Function() onAuthFailure,
  })  : _storage = storage,
        _refreshDio = refreshDio,
        _onAuthFailure = onAuthFailure;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    if (path.contains(AuthBackendConfig.googleTokenPath) ||
        path.contains(AuthBackendConfig.refreshTokenPath)) {
      return handler.next(options);
    }

    _storage.accessToken.then((token) {
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    });
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final path = err.requestOptions.path;
    if (path.contains(AuthBackendConfig.googleTokenPath) ||
        path.contains(AuthBackendConfig.refreshTokenPath)) {
      return handler.next(err);
    }

    if (err.requestOptions.extra['retried'] == true) {
      return handler.next(err);
    }

    if (_refreshing != null) {
      _refreshing!.future.then((_) {
        _retry(err, handler);
      });
      return;
    }

    _refreshing = Completer<void>();
    _refreshDio
        .post(
          AuthBackendConfig.refreshTokenPath,
          data: {'refreshToken': _storage.refreshToken},
        )
        .then((response) async {
      final data = response.data as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      await _storage.setAccessToken(newAccessToken);
      await _storage.setRefreshToken(newRefreshToken);

      _refreshing?.complete();
      _refreshing = null;
      _retry(err, handler);
    }).catchError((e) {
      _refreshing?.completeError(e);
      _refreshing = null;
      _onAuthFailure().then((_) {
        handler.next(err);
      });
    });
  }

  void _retry(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    options.extra['retried'] = true;
    _storage.accessToken.then((token) {
      options.headers['Authorization'] = 'Bearer $token';
    }).then((_) {
      handler.next(err);
    });
  }
}