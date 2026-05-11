import 'package:dio/dio.dart';

import '../../../core/config/google_config.dart';
import '../../auth/domain/profile.dart';

class ProfileApi {
  ProfileApi(this._dio);

  final Dio _dio;

  Future<Profile> update(
    String profileId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.patch(
      '${AuthBackendConfig.profilesPath}/$profileId',
      data: payload,
    );
    return Profile.fromJson(response.data as Map<String, dynamic>);
  }
}
