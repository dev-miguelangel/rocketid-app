import 'activity.dart';
import 'activity_enums.dart';

DateTime? _parseDate(Object? v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

/// Una fila de `activity_participants`: inscripción, invitación o convocatoria
/// de un usuario en una actividad.
class ActivityParticipant {
  const ActivityParticipant({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.status,
    this.subteam,
    this.participantRole,
    required this.isExternal,
    this.invitedById,
    this.respondedAt,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  final String id;
  final String activityId;
  final String userId;
  final ParticipantStatus status;
  final Subteam? subteam;
  final ParticipantRole? participantRole;
  final bool isExternal;
  final String? invitedById;
  final DateTime? respondedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ActivityUserRef? user;

  /// Copia con cambios. Solo sobreescribe los campos no nulos pasados; pensado
  /// para reflejar localmente una reasignación de subequipo/rol.
  ActivityParticipant copyWith({
    ParticipantStatus? status,
    Subteam? subteam,
    ParticipantRole? participantRole,
  }) {
    return ActivityParticipant(
      id: id,
      activityId: activityId,
      userId: userId,
      status: status ?? this.status,
      subteam: subteam ?? this.subteam,
      participantRole: participantRole ?? this.participantRole,
      isExternal: isExternal,
      invitedById: invitedById,
      respondedAt: respondedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      user: user,
    );
  }

  factory ActivityParticipant.fromJson(Map<String, dynamic> json) {
    return ActivityParticipant(
      id: (json['id'] ?? '').toString(),
      activityId:
          (json['activityId'] ?? json['activity_id'] ?? '').toString(),
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      status: participantStatusFromApi(json['status']),
      subteam: subteamFromApi(json['subteam']),
      participantRole: participantRoleFromApi(
        json['participantRole'] ?? json['participant_role'],
      ),
      isExternal:
          json['isExternal'] == true || json['is_external'] == true,
      invitedById:
          (json['invitedById'] ?? json['invited_by_id'])?.toString(),
      respondedAt: _parseDate(json['respondedAt'] ?? json['responded_at']),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
      user: ActivityUserRef.fromJson(json['user']),
    );
  }
}
