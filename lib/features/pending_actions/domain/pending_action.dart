/// Modelo del inbox de acciones pendientes (`GET /pending-actions`).
///
/// El endpoint agrupa las acciones en cuatro categorías; aquí se aplanan en una
/// sola lista de [PendingAction] para mostrarlas ordenadas por fecha.
library;

/// Categoría de una acción pendiente. Determina con qué flujo se resuelve y qué
/// iconos/etiquetas usar en el sheet de acciones rápidas.
enum PendingActionKind {
  /// Invitación a una actividad recibida (participante `invited`).
  activityInvitation,

  /// Convocatoria a un entrenamiento (participante `pending` de un `training`).
  trainingConvocation,

  /// Solicitud de ingreso a un equipo donde soy propietario o capitán.
  teamJoinRequest,

  /// Inscripción por aprobar en una de mis convocatorias públicas.
  activityRegistrationRequest;

  /// Etiqueta corta para el chip de tipo en la lista.
  String get chipLabel => switch (this) {
        PendingActionKind.activityInvitation => 'Invitación',
        PendingActionKind.trainingConvocation => 'Convocatoria',
        PendingActionKind.teamJoinRequest => 'Solicitud',
        PendingActionKind.activityRegistrationRequest => 'Inscripción',
      };
}

/// Una fila de la lista de pendientes, unificando las cuatro categorías.
class PendingAction {
  const PendingAction({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.title,
    this.subtitle,
    this.activityId,
    this.teamId,
    this.requesterUserId,
  });

  /// Id del registro pendiente (participante o miembro de equipo).
  final String id;
  final PendingActionKind kind;
  final DateTime createdAt;

  /// Línea principal de la fila.
  final String title;

  /// Línea secundaria opcional (deporte, equipo, actividad…).
  final String? subtitle;

  /// Actividad relacionada, si aplica al [kind].
  final String? activityId;

  /// Equipo relacionado, si aplica al [kind].
  final String? teamId;

  /// Usuario que originó la solicitud (para [kind] de tipo solicitud).
  final String? requesterUserId;

  // --- Factories por categoría ----------------------------------------------

  /// `activityInvitations`: invitación a una actividad recibida.
  factory PendingAction.fromInvitationJson(Map<String, dynamic> json) {
    final activity = _asMap(json['activity']);
    final sport = _asMap(activity['sport']);
    final organizer = _asMap(activity['organizer']);
    return PendingAction(
      id: _str(json['id']),
      kind: PendingActionKind.activityInvitation,
      createdAt: _date(json['createdAt']),
      activityId: _strOrNull(json['activityId']) ?? _strOrNull(activity['id']),
      title: _titleOr(activity['title'], 'Actividad'),
      subtitle: _join([
        _strOrNull(sport['label']),
        _prefix('Invita ', _strOrNull(organizer['name'])),
      ]),
    );
  }

  /// `trainingConvocations`: convocatoria a un entrenamiento.
  factory PendingAction.fromConvocationJson(Map<String, dynamic> json) {
    final activity = _asMap(json['activity']);
    final sport = _asMap(activity['sport']);
    final team = _asMap(activity['team']);
    return PendingAction(
      id: _str(json['id']),
      kind: PendingActionKind.trainingConvocation,
      createdAt: _date(json['createdAt']),
      activityId: _strOrNull(json['activityId']) ?? _strOrNull(activity['id']),
      title: _titleOr(activity['title'], 'Entrenamiento'),
      subtitle: _join([
        _prefix('Equipo ', _strOrNull(team['name'])),
        _strOrNull(sport['label']),
      ]),
    );
  }

  /// `teamJoinRequests`: solicitud de ingreso a un equipo que debo resolver.
  factory PendingAction.fromJoinRequestJson(Map<String, dynamic> json) {
    final team = _asMap(json['team']);
    final user = _asMap(json['user']);
    final teamName = _strOrNull(team['name']);
    return PendingAction(
      id: _str(json['id']),
      kind: PendingActionKind.teamJoinRequest,
      createdAt: _date(json['createdAt']),
      teamId: _strOrNull(json['teamId']) ?? _strOrNull(team['id']),
      requesterUserId: _strOrNull(json['userId']) ?? _strOrNull(user['id']),
      title: _userName(user),
      subtitle: teamName == null
          ? 'Quiere unirse a tu equipo'
          : 'Quiere unirse a $teamName',
    );
  }

  /// `activityRegistrationRequests`: inscripción por aprobar en mi convocatoria.
  factory PendingAction.fromRegistrationJson(Map<String, dynamic> json) {
    final activity = _asMap(json['activity']);
    final user = _asMap(json['user']);
    final activityTitle = _strOrNull(activity['title']);
    return PendingAction(
      id: _str(json['id']),
      kind: PendingActionKind.activityRegistrationRequest,
      createdAt: _date(json['createdAt']),
      activityId: _strOrNull(json['activityId']) ?? _strOrNull(activity['id']),
      requesterUserId: _strOrNull(json['userId']) ?? _strOrNull(user['id']),
      title: _userName(user),
      subtitle: activityTitle == null
          ? 'Quiere inscribirse en tu convocatoria'
          : 'Quiere inscribirse en $activityTitle',
    );
  }
}

/// Inbox completo de acciones pendientes.
class PendingActionsInbox {
  const PendingActionsInbox({required this.actions, required this.total});

  /// Acciones aplanadas y ordenadas por fecha (más reciente primero).
  final List<PendingAction> actions;

  /// Total de acciones pendientes (del campo `total` del endpoint).
  final int total;

  /// Construye el inbox a partir de la respuesta del endpoint.
  factory PendingActionsInbox.fromJson(Map<String, dynamic> json) {
    final actions = <PendingAction>[
      ..._mapList(json['activityInvitations'],
          PendingAction.fromInvitationJson),
      ..._mapList(json['trainingConvocations'],
          PendingAction.fromConvocationJson),
      ..._mapList(json['teamJoinRequests'], PendingAction.fromJoinRequestJson),
      ..._mapList(json['activityRegistrationRequests'],
          PendingAction.fromRegistrationJson),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final reportedTotal = json['total'];
    return PendingActionsInbox(
      actions: actions,
      total: reportedTotal is num ? reportedTotal.toInt() : actions.length,
    );
  }

  static List<PendingAction> _mapList(
    dynamic raw,
    PendingAction Function(Map<String, dynamic>) build,
  ) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(build)
        .toList(growable: false);
  }
}

// --- Helpers de parseo --------------------------------------------------------

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};

String _str(dynamic value) => value?.toString() ?? '';

String? _strOrNull(dynamic value) {
  final s = value?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

DateTime _date(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal() ?? DateTime.now();

String _titleOr(dynamic value, String fallback) =>
    _strOrNull(value) ?? fallback;

/// Nombre visible de un usuario: `name`, o `@alias`, o `Usuario`.
String _userName(Map<String, dynamic> user) {
  final name = _strOrNull(user['name']);
  if (name != null) return name;
  final alias = _strOrNull(_asMap(user['profile'])['alias']);
  return alias != null ? '@$alias' : 'Usuario';
}

String? _prefix(String prefix, String? value) =>
    value == null ? null : '$prefix$value';

String? _join(List<String?> parts) {
  final present = parts.whereType<String>().toList();
  return present.isEmpty ? null : present.join(' · ');
}
