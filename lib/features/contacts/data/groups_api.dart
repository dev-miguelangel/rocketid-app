import 'package:dio/dio.dart';

import '../../../core/config/google_config.dart';
import '../domain/contact_group.dart';

class GroupsApi {
  GroupsApi(this._dio);

  final Dio _dio;

  Future<List<ContactGroup>> list() async {
    final response = await _dio.get(AuthBackendConfig.groupsPath);
    return _parseList(response.data);
  }

  Future<ContactGroup> getById(String id) async {
    final response = await _dio.get('${AuthBackendConfig.groupsPath}/$id');
    return _parseOne(response.data);
  }

  Future<ContactGroup> create(String name) async {
    final response = await _dio.post(
      AuthBackendConfig.groupsPath,
      data: <String, dynamic>{'name': name},
    );
    return _parseOne(response.data);
  }

  Future<ContactGroup> rename(String id, String name) async {
    final response = await _dio.patch(
      '${AuthBackendConfig.groupsPath}/$id',
      data: <String, dynamic>{'name': name},
    );
    return _parseOne(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('${AuthBackendConfig.groupsPath}/$id');
  }

  Future<ContactGroup?> addContacts(String id, List<String> contactIds) async {
    final response = await _dio.post(
      '${AuthBackendConfig.groupsPath}/$id/contacts',
      data: <String, dynamic>{'contactIds': contactIds},
    );
    return _tryParseOne(response.data);
  }

  Future<ContactGroup?> removeContacts(
    String id,
    List<String> contactIds,
  ) async {
    final response = await _dio.delete(
      '${AuthBackendConfig.groupsPath}/$id/contacts',
      data: <String, dynamic>{'contactIds': contactIds},
    );
    return _tryParseOne(response.data);
  }

  static List<ContactGroup> _parseList(dynamic data) {
    final raw = data is Map<String, dynamic>
        ? (data['data'] ?? data['groups'] ?? data['items'] ?? data)
        : data;
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ContactGroup.fromJson)
        .toList(growable: false);
  }

  static ContactGroup _parseOne(dynamic data) {
    final parsed = _tryParseOne(data);
    if (parsed == null) {
      throw const FormatException('Respuesta de grupo inválida');
    }
    return parsed;
  }

  static ContactGroup? _tryParseOne(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'] ?? data['group'] ?? data;
      if (inner is Map<String, dynamic>) {
        return ContactGroup.fromJson(inner);
      }
    }
    return null;
  }
}
