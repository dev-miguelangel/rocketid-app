import 'package:dio/dio.dart';

import '../../../core/config/google_config.dart';
import '../domain/sport.dart';

class SportsApi {
  SportsApi(this._dio);

  final Dio _dio;

  Future<List<Sport>> list() async {
    final response = await _dio.get(AuthBackendConfig.sportsPath);
    final data = response.data;
    final raw = data is Map<String, dynamic>
        ? (data['data'] ?? data['sports'] ?? data['items'] ?? data)
        : data;
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Sport.fromJson)
        .toList(growable: false);
  }
}
