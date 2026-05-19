import '../../teams/domain/sport.dart';
import '../../teams/domain/team.dart';
import 'activity_enums.dart';

/// Referencia ligera a un usuario dentro de una actividad.
///
/// Las respuestas de lista y de participantes solo traen `id`, `name` y un
/// `profile` parcial (`alias`, `stringId`), sin `email`; por eso no se puede
/// reutilizar el modelo `User` (que exige `email`).
class ActivityUserRef {
  const ActivityUserRef({
    required this.id,
    this.name,
    this.email,
    this.alias,
    this.stringId,
  });

  final String id;
  final String? name;
  final String? email;
  final String? alias;
  final String? stringId;

  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final a = alias?.trim();
    if (a != null && a.isNotEmpty) return a;
    return email?.trim() ?? 'Usuario';
  }

  static ActivityUserRef? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final profile = json['profile'];
    final profileMap =
        profile is Map<String, dynamic> ? profile : const <String, dynamic>{};
    return ActivityUserRef(
      id: (json['id'] ?? json['userId'] ?? json['user_id'] ?? '').toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      alias: profileMap['alias']?.toString(),
      stringId: profileMap['stringId']?.toString(),
    );
  }
}

double _parseDouble(Object? v) {
  if (v is num) return v.toDouble();
  return double.tryParse('${v ?? ''}') ?? 0;
}

int? _parseIntOrNull(Object? v) {
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? ''}');
}

DateTime? _parseDate(Object? v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

Team? _parseTeam(Object? v) =>
    v is Map<String, dynamic> ? Team.fromJson(v) : null;

/// Una actividad (tabla `activities`, con discriminador `type`).
///
/// Los campos específicos de un tipo llegan `null` cuando no aplican.
class Activity {
  const Activity({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    this.description,
    required this.sportId,
    required this.requiresRegistration,
    this.registrationDeadline,
    required this.startsAt,
    required this.endsAt,
    required this.latitude,
    required this.longitude,
    this.locationInstructions,
    required this.organizerId,
    this.organizerAlias,
    this.organizerStringId,
    this.teamOneId,
    this.teamTwoId,
    this.teamId,
    this.trainingMode,
    this.playersPerSubteam,
    this.reservesPerSubteam,
    required this.allowExternals,
    this.openCallMode,
    this.maxParticipants,
    this.usedSpots = 0,
    this.availableSpots,
    this.createdAt,
    this.updatedAt,
    this.sport,
    this.organizer,
    this.teamOne,
    this.teamTwo,
    this.team,
  });

  final String id;
  final ActivityType type;
  final ActivityStatus status;
  final String title;
  final String? description;
  final int sportId;
  final bool requiresRegistration;
  final DateTime? registrationDeadline;
  final DateTime startsAt;
  final DateTime endsAt;
  final double latitude;
  final double longitude;
  final String? locationInstructions;
  final String organizerId;

  /// Alias y stringId del perfil del organizador, expuestos por la API en el
  /// nivel raíz (presentes en lista y detalle).
  final String? organizerAlias;
  final String? organizerStringId;

  // Desafío entre equipos.
  final String? teamOneId;
  final String? teamTwoId;

  // Entrenamiento.
  final String? teamId;
  final TrainingMode? trainingMode;
  final int? playersPerSubteam;
  final int? reservesPerSubteam;
  final bool allowExternals;

  // Convocatoria.
  final OpenCallMode? openCallMode;
  final int? maxParticipants;

  /// Cupos utilizados: participantes en estado `confirmed`.
  final int usedSpots;

  /// Cupos disponibles (`maxParticipants - usedSpots`); `null` si la actividad
  /// no tiene cupo máximo.
  final int? availableSpots;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Objetos anidados (presentes según el endpoint).
  final Sport? sport;
  final ActivityUserRef? organizer;
  final Team? teamOne;
  final Team? teamTwo;
  final Team? team;

  String get displayTitle => title.trim().isNotEmpty ? title.trim() : 'Actividad';

  bool get isCancelled => status == ActivityStatus.cancelled;

  /// `true` si la actividad tiene cupo máximo y ya no quedan cupos libres.
  bool get isFull => availableSpots != null && availableSpots! <= 0;

  /// Una convocatoria `open` o `public` admite inscripción directa.
  bool get isOpenForRegister =>
      type == ActivityType.openCall &&
      !isCancelled &&
      (openCallMode == OpenCallMode.open ||
          openCallMode == OpenCallMode.public);

  factory Activity.fromJson(Map<String, dynamic> json) {
    final sportJson = json['sport'];
    return Activity(
      id: (json['id'] ?? '').toString(),
      type: activityTypeFromApi(json['type']),
      status: activityStatusFromApi(json['status']),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      sportId: _parseIntOrNull(json['sportId'] ?? json['sport_id']) ?? 0,
      requiresRegistration:
          json['requiresRegistration'] == true ||
          json['requires_registration'] == true,
      registrationDeadline: _parseDate(
        json['registrationDeadline'] ?? json['registration_deadline'],
      ),
      startsAt: _parseDate(json['startsAt'] ?? json['starts_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endsAt: _parseDate(json['endsAt'] ?? json['ends_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      locationInstructions:
          (json['locationInstructions'] ?? json['location_instructions'])
              ?.toString(),
      organizerId:
          (json['organizerId'] ?? json['organizer_id'] ?? '').toString(),
      organizerAlias:
          (json['organizer_alias'] ?? json['organizerAlias'])?.toString(),
      organizerStringId:
          (json['organizer_stringId'] ?? json['organizerStringId'])
              ?.toString(),
      teamOneId: (json['teamOneId'] ?? json['team_one_id'])?.toString(),
      teamTwoId: (json['teamTwoId'] ?? json['team_two_id'])?.toString(),
      teamId: (json['teamId'] ?? json['team_id'])?.toString(),
      trainingMode:
          trainingModeFromApi(json['trainingMode'] ?? json['training_mode']),
      playersPerSubteam: _parseIntOrNull(
        json['playersPerSubteam'] ?? json['players_per_subteam'],
      ),
      reservesPerSubteam: _parseIntOrNull(
        json['reservesPerSubteam'] ?? json['reserves_per_subteam'],
      ),
      allowExternals: json['allowExternals'] == true ||
          json['allow_externals'] == true,
      openCallMode:
          openCallModeFromApi(json['openCallMode'] ?? json['open_call_mode']),
      maxParticipants: _parseIntOrNull(
        json['maxParticipants'] ?? json['max_participants'],
      ),
      usedSpots:
          _parseIntOrNull(json['usedSpots'] ?? json['used_spots']) ?? 0,
      availableSpots: _parseIntOrNull(
        json['availableSpots'] ?? json['available_spots'],
      ),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
      sport: sportJson is Map<String, dynamic>
          ? Sport.fromJson(sportJson)
          : null,
      organizer: ActivityUserRef.fromJson(json['organizer']),
      teamOne: _parseTeam(json['teamOne']),
      teamTwo: _parseTeam(json['teamTwo']),
      team: _parseTeam(json['team']),
    );
  }
}
