import 'activity_enums.dart';

/// Filtro inmutable para la agenda de actividades (`GET /activities`).
///
/// Se usa como clave de `FutureProvider.family`, por eso implementa
/// `==`/`hashCode` por valor.
class ActivityFilter {
  const ActivityFilter({
    this.from,
    this.to,
    this.type,
    this.status,
    this.sportId,
    this.teamId,
  });

  final DateTime? from;
  final DateTime? to;
  final ActivityType? type;
  final ActivityStatus? status;
  final int? sportId;
  final String? teamId;

  static const empty = ActivityFilter();

  ActivityFilter copyWith({
    DateTime? from,
    DateTime? to,
    Object? type = _sentinel,
    Object? status = _sentinel,
    Object? sportId = _sentinel,
    Object? teamId = _sentinel,
  }) {
    return ActivityFilter(
      from: from ?? this.from,
      to: to ?? this.to,
      type: type == _sentinel ? this.type : type as ActivityType?,
      status: status == _sentinel ? this.status : status as ActivityStatus?,
      sportId: sportId == _sentinel ? this.sportId : sportId as int?,
      teamId: teamId == _sentinel ? this.teamId : teamId as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ActivityFilter &&
      other.from == from &&
      other.to == to &&
      other.type == type &&
      other.status == status &&
      other.sportId == sportId &&
      other.teamId == teamId;

  @override
  int get hashCode => Object.hash(from, to, type, status, sportId, teamId);
}

const Object _sentinel = Object();
