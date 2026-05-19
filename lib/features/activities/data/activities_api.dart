import 'package:dio/dio.dart';

import '../../../core/config/google_config.dart';
import '../domain/activity.dart';
import '../domain/activity_enums.dart';
import '../domain/activity_filter.dart';
import '../domain/activity_participant.dart';

/// Cliente HTTP de la feature de Actividades.
///
/// Cubre los endpoints de `docs/actividades-api.md` §2 y §3. El token JWT lo
/// inyecta el interceptor de `dioProvider`.
class ActivitiesApi {
  ActivitiesApi(this._dio);

  final Dio _dio;

  String get _base => AuthBackendConfig.activitiesPath;

  // --- Actividades ----------------------------------------------------------

  /// `POST /activities`. El cuerpo varía según `type` (ver §2.1).
  Future<Activity> create(Map<String, dynamic> body) async {
    final response = await _dio.post(_base, data: body);
    return _parseActivity(response.data);
  }

  /// `GET /activities` — agenda con filtros opcionales.
  Future<List<Activity>> list(ActivityFilter filter) async {
    final query = <String, dynamic>{
      if (filter.from != null) 'from': filter.from!.toUtc().toIso8601String(),
      if (filter.to != null) 'to': filter.to!.toUtc().toIso8601String(),
      if (filter.type != null) 'type': activityTypeToApi(filter.type!),
      if (filter.status != null) 'status': activityStatusToApi(filter.status!),
      if (filter.sportId != null) 'sportId': filter.sportId,
      if (filter.teamId != null) 'teamId': filter.teamId,
    };
    final response = await _dio.get(
      _base,
      queryParameters: query.isEmpty ? null : query,
    );
    return _parseActivityList(response.data);
  }

  /// `GET /activities/mine` — actividades que el usuario organiza o participa.
  Future<List<Activity>> mine() async {
    final response = await _dio.get('$_base/mine');
    return _parseActivityList(response.data);
  }

  /// `GET /activities/:id`.
  Future<Activity> getById(String id) async {
    final response = await _dio.get('$_base/$id');
    return _parseActivity(response.data);
  }

  /// `PATCH /activities/:id` — solo campos comunes (`type` es inmutable).
  Future<Activity> update(String id, Map<String, dynamic> patch) async {
    final response = await _dio.patch('$_base/$id', data: patch);
    return _parseActivity(response.data);
  }

  /// `POST /activities/:id/cancel`.
  Future<Activity> cancel(String id) async {
    final response = await _dio.post('$_base/$id/cancel');
    return _parseActivity(response.data);
  }

  /// `DELETE /activities/:id` — solo el organizador.
  Future<void> delete(String id) async {
    await _dio.delete('$_base/$id');
  }

  // --- Participación --------------------------------------------------------

  /// `GET /activities/:id/participants`.
  Future<List<ActivityParticipant>> participants(
    String id, {
    ParticipantStatus? status,
  }) async {
    final response = await _dio.get(
      '$_base/$id/participants',
      queryParameters: status == null
          ? null
          : <String, dynamic>{'status': participantStatusToApi(status)},
    );
    return _parseParticipantList(response.data);
  }

  /// `POST /activities/:id/register` — inscribirse en una convocatoria.
  Future<ActivityParticipant> register(String id) async {
    final response = await _dio.post('$_base/$id/register');
    return _parseParticipant(response.data);
  }

  /// `POST /activities/:id/withdraw` — retirarse.
  Future<void> withdraw(String id) async {
    await _dio.post('$_base/$id/withdraw');
  }

  /// `POST /activities/:id/registrations/:userId` — el organizador resuelve
  /// una solicitud `pending`. [action] es `confirm` o `reject`.
  Future<ActivityParticipant> resolveRegistration(
    String id,
    String userId,
    String action,
  ) async {
    final response = await _dio.post(
      '$_base/$id/registrations/$userId',
      data: <String, dynamic>{'action': action},
    );
    return _parseParticipant(response.data);
  }

  /// `POST /activities/:id/invitations` — invitar participantes.
  Future<List<ActivityParticipant>> invite(
    String id,
    List<String> userIds,
  ) async {
    final response = await _dio.post(
      '$_base/$id/invitations',
      data: <String, dynamic>{'userIds': userIds},
    );
    return _parseParticipantList(response.data);
  }

  /// `POST /activities/:id/invitation/accept`.
  Future<ActivityParticipant> acceptInvitation(String id) async {
    final response = await _dio.post('$_base/$id/invitation/accept');
    return _parseParticipant(response.data);
  }

  /// `POST /activities/:id/invitation/decline`.
  Future<ActivityParticipant> declineInvitation(String id) async {
    final response = await _dio.post('$_base/$id/invitation/decline');
    return _parseParticipant(response.data);
  }

  /// `POST /activities/:id/attendance/confirm` — entrenamiento.
  Future<ActivityParticipant> confirmAttendance(String id) async {
    final response = await _dio.post('$_base/$id/attendance/confirm');
    return _parseParticipant(response.data);
  }

  /// `POST /activities/:id/attendance/decline` — entrenamiento.
  Future<ActivityParticipant> declineAttendance(String id) async {
    final response = await _dio.post('$_base/$id/attendance/decline');
    return _parseParticipant(response.data);
  }

  /// `POST /activities/:id/subteams/assign` — desafío interno.
  Future<ActivityParticipant> assignSubteam(
    String id, {
    required String userId,
    required Subteam subteam,
    required ParticipantRole role,
  }) async {
    final response = await _dio.post(
      '$_base/$id/subteams/assign',
      data: <String, dynamic>{
        'userId': userId,
        'subteam': subteamToApi(subteam),
        'participantRole': participantRoleToApi(role),
      },
    );
    return _parseParticipant(response.data);
  }

  // --- Parseo ---------------------------------------------------------------

  static List<Activity> _parseActivityList(dynamic data) {
    final raw = data is Map<String, dynamic>
        ? (data['data'] ?? data['activities'] ?? data['items'] ?? data)
        : data;
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Activity.fromJson)
        .toList(growable: false);
  }

  static Activity _parseActivity(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'] ?? data['activity'] ?? data;
      if (inner is Map<String, dynamic>) return Activity.fromJson(inner);
    }
    throw const FormatException('Respuesta de actividad inválida');
  }

  static List<ActivityParticipant> _parseParticipantList(dynamic data) {
    final raw = data is Map<String, dynamic>
        ? (data['data'] ?? data['participants'] ?? data['items'] ?? data)
        : data;
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ActivityParticipant.fromJson)
        .toList(growable: false);
  }

  static ActivityParticipant _parseParticipant(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'] ?? data['participant'] ?? data;
      if (inner is Map<String, dynamic>) {
        return ActivityParticipant.fromJson(inner);
      }
    }
    throw const FormatException('Respuesta de participante inválida');
  }
}

/// Traduce un [DioException] de la API de actividades a un mensaje en español.
String activityErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final msg = data['message'];
    if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    if (msg is List && msg.isNotEmpty) return msg.first.toString();
  }
  final status = e.response?.statusCode;
  if (status == 403) return 'No tienes permisos para esta acción';
  if (status == 404) return 'No se encontró el recurso';
  if (status == 409) return 'La acción no se pudo completar';
  return 'Algo salió mal. Inténtalo de nuevo.';
}
