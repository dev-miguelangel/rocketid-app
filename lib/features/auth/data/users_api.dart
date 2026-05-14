import 'package:dio/dio.dart';

import '../../../core/config/google_config.dart';

class UsersApi {
  UsersApi(this._dio);

  final Dio _dio;

  Future<int> updateOnboardingStep(int step) async {
    final response = await _dio.patch(
      AuthBackendConfig.usersOnboardingPath,
      data: {'onboardingStep': step},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final raw = data['onboardingStep'] ?? data['user']?['onboardingStep'];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
    }
    return step;
  }
}
