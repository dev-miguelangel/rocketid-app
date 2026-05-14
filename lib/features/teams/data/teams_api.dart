import 'package:dio/dio.dart';

import '../../../core/config/google_config.dart';
import '../domain/team.dart';

class TeamsApi {
  TeamsApi(this._dio);

  final Dio _dio;

  String get _base => AuthBackendConfig.teamsPath;

  Future<List<Team>> list() async {
    final response = await _dio.get(_base);
    return _parseTeamList(response.data);
  }

  Future<Team> getById(String id) async {
    final response = await _dio.get('$_base/$id');
    return _parseTeam(response.data);
  }

  Future<Team> create({
    required String name,
    String? description,
    required String icon,
    required String color,
    required String gender,
    required int sportId,
  }) async {
    final response = await _dio.post(
      _base,
      data: <String, dynamic>{
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        'icon': icon,
        'color': color,
        'gender': gender,
        'sportId': sportId,
      },
    );
    return _parseTeam(response.data);
  }

  Future<Team> update(String id, Map<String, dynamic> patch) async {
    final response = await _dio.patch('$_base/$id', data: patch);
    return _parseTeam(response.data);
  }

  Future<void> delete(String id) async {
    await _dio.delete('$_base/$id');
  }

  Future<List<TeamMember>> members(String id) async {
    final response = await _dio.get('$_base/$id/members');
    return _parseMemberList(response.data);
  }

  Future<void> addMember(
    String id, {
    required String userId,
    String role = 'member',
  }) async {
    await _dio.post(
      '$_base/$id/members',
      data: <String, dynamic>{
        'userId': userId,
        'action': 'add',
        'role': role,
      },
    );
  }

  Future<void> removeMember(String id, String userId) async {
    await _dio.delete('$_base/$id/members/$userId');
  }

  Future<void> updateMemberRole(String id, String userId, String role) async {
    await _dio.patch(
      '$_base/$id/members/$userId/role',
      data: <String, dynamic>{'role': role},
    );
  }

  Future<void> requestJoin(String id) async {
    await _dio.post('$_base/$id/join');
  }

  Future<void> leave(String id) async {
    await _dio.post('$_base/$id/leave');
  }

  Future<List<TeamMember>> pendingRequests(String id) async {
    final response = await _dio.get('$_base/$id/requests');
    return _parseMemberList(response.data);
  }

  Future<void> acceptRequest(String id, String userId) async {
    await _dio.post('$_base/$id/requests/$userId/accept');
  }

  Future<void> rejectRequest(String id, String userId) async {
    await _dio.post('$_base/$id/requests/$userId/reject');
  }

  // ---------------------------------------------------------------------------

  static List<Team> _parseTeamList(dynamic data) {
    final raw = data is Map<String, dynamic>
        ? (data['data'] ?? data['teams'] ?? data['items'] ?? data)
        : data;
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Team.fromJson)
        .toList(growable: false);
  }

  static Team _parseTeam(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'] ?? data['team'] ?? data;
      if (inner is Map<String, dynamic>) return Team.fromJson(inner);
    }
    throw const FormatException('Respuesta de equipo inválida');
  }

  static List<TeamMember> _parseMemberList(dynamic data) {
    final raw = data is Map<String, dynamic>
        ? (data['data'] ?? data['members'] ?? data['requests'] ?? data['items'] ?? data)
        : data;
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TeamMember.fromJson)
        .toList(growable: false);
  }
}

String teamErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final msg = data['message'];
    if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    if (msg is List && msg.isNotEmpty) return msg.first.toString();
  }
  final status = e.response?.statusCode;
  if (status == 403) return 'No tienes permisos para esta acción';
  if (status == 404) return 'No se encontró el recurso';
  return 'Algo salió mal. Inténtalo de nuevo.';
}
