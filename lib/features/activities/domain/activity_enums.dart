/// Enums de la feature de Actividades.
///
/// Los valores de cadena de la API coinciden con los enums del backend
/// (snake_case). Ver `docs/actividades-api.md` §1.
library;

// ---------------------------------------------------------------------------
// ActivityType
// ---------------------------------------------------------------------------

enum ActivityType { challenge, training, openCall }

ActivityType activityTypeFromApi(Object? v) {
  switch (v?.toString()) {
    case 'challenge':
      return ActivityType.challenge;
    case 'training':
      return ActivityType.training;
    case 'open_call':
    default:
      return ActivityType.openCall;
  }
}

String activityTypeToApi(ActivityType t) {
  switch (t) {
    case ActivityType.challenge:
      return 'challenge';
    case ActivityType.training:
      return 'training';
    case ActivityType.openCall:
      return 'open_call';
  }
}

String activityTypeLabel(ActivityType t) {
  switch (t) {
    case ActivityType.challenge:
      return 'Desafío';
    case ActivityType.training:
      return 'Entrenamiento';
    case ActivityType.openCall:
      return 'Convocatoria';
  }
}

// ---------------------------------------------------------------------------
// ActivityStatus
// ---------------------------------------------------------------------------

enum ActivityStatus { scheduled, inProgress, completed, cancelled }

ActivityStatus activityStatusFromApi(Object? v) {
  switch (v?.toString()) {
    case 'in_progress':
      return ActivityStatus.inProgress;
    case 'completed':
      return ActivityStatus.completed;
    case 'cancelled':
      return ActivityStatus.cancelled;
    case 'scheduled':
    default:
      return ActivityStatus.scheduled;
  }
}

String activityStatusToApi(ActivityStatus s) {
  switch (s) {
    case ActivityStatus.scheduled:
      return 'scheduled';
    case ActivityStatus.inProgress:
      return 'in_progress';
    case ActivityStatus.completed:
      return 'completed';
    case ActivityStatus.cancelled:
      return 'cancelled';
  }
}

String activityStatusLabel(ActivityStatus s) {
  switch (s) {
    case ActivityStatus.scheduled:
      return 'Programada';
    case ActivityStatus.inProgress:
      return 'En curso';
    case ActivityStatus.completed:
      return 'Finalizada';
    case ActivityStatus.cancelled:
      return 'Cancelada';
  }
}

// ---------------------------------------------------------------------------
// TrainingMode
// ---------------------------------------------------------------------------

enum TrainingMode { classic, internalChallenge }

TrainingMode? trainingModeFromApi(Object? v) {
  switch (v?.toString()) {
    case 'classic':
      return TrainingMode.classic;
    case 'internal_challenge':
      return TrainingMode.internalChallenge;
    default:
      return null;
  }
}

String trainingModeToApi(TrainingMode m) {
  switch (m) {
    case TrainingMode.classic:
      return 'classic';
    case TrainingMode.internalChallenge:
      return 'internal_challenge';
  }
}

String trainingModeLabel(TrainingMode m) {
  switch (m) {
    case TrainingMode.classic:
      return 'Clásico';
    case TrainingMode.internalChallenge:
      return 'Desafío interno';
  }
}

// ---------------------------------------------------------------------------
// OpenCallMode
// ---------------------------------------------------------------------------

enum OpenCallMode { open, public, private }

OpenCallMode? openCallModeFromApi(Object? v) {
  switch (v?.toString()) {
    case 'open':
      return OpenCallMode.open;
    case 'public':
      return OpenCallMode.public;
    case 'private':
      return OpenCallMode.private;
    default:
      return null;
  }
}

String openCallModeToApi(OpenCallMode m) {
  switch (m) {
    case OpenCallMode.open:
      return 'open';
    case OpenCallMode.public:
      return 'public';
    case OpenCallMode.private:
      return 'private';
  }
}

String openCallModeLabel(OpenCallMode m) {
  switch (m) {
    case OpenCallMode.open:
      return 'Abierta';
    case OpenCallMode.public:
      return 'Pública';
    case OpenCallMode.private:
      return 'Privada';
  }
}

// ---------------------------------------------------------------------------
// ParticipantStatus
// ---------------------------------------------------------------------------

enum ParticipantStatus { invited, pending, confirmed, declined, cancelled }

ParticipantStatus participantStatusFromApi(Object? v) {
  switch (v?.toString()) {
    case 'invited':
      return ParticipantStatus.invited;
    case 'confirmed':
      return ParticipantStatus.confirmed;
    case 'declined':
      return ParticipantStatus.declined;
    case 'cancelled':
      return ParticipantStatus.cancelled;
    case 'pending':
    default:
      return ParticipantStatus.pending;
  }
}

String participantStatusToApi(ParticipantStatus s) {
  switch (s) {
    case ParticipantStatus.invited:
      return 'invited';
    case ParticipantStatus.pending:
      return 'pending';
    case ParticipantStatus.confirmed:
      return 'confirmed';
    case ParticipantStatus.declined:
      return 'declined';
    case ParticipantStatus.cancelled:
      return 'cancelled';
  }
}

String participantStatusLabel(ParticipantStatus s) {
  switch (s) {
    case ParticipantStatus.invited:
      return 'Invitado';
    case ParticipantStatus.pending:
      return 'Pendiente';
    case ParticipantStatus.confirmed:
      return 'Confirmado';
    case ParticipantStatus.declined:
      return 'Rechazado';
    case ParticipantStatus.cancelled:
      return 'Cancelado';
  }
}

// ---------------------------------------------------------------------------
// Subteam
// ---------------------------------------------------------------------------

enum Subteam { one, two }

Subteam? subteamFromApi(Object? v) {
  switch (v?.toString()) {
    case 'one':
      return Subteam.one;
    case 'two':
      return Subteam.two;
    default:
      return null;
  }
}

String subteamToApi(Subteam s) => s == Subteam.one ? 'one' : 'two';

String subteamLabel(Subteam s) => s == Subteam.one ? 'Equipo 1' : 'Equipo 2';

// ---------------------------------------------------------------------------
// ParticipantRole
// ---------------------------------------------------------------------------

enum ParticipantRole { starter, reserve }

ParticipantRole? participantRoleFromApi(Object? v) {
  switch (v?.toString()) {
    case 'starter':
      return ParticipantRole.starter;
    case 'reserve':
      return ParticipantRole.reserve;
    default:
      return null;
  }
}

String participantRoleToApi(ParticipantRole r) =>
    r == ParticipantRole.starter ? 'starter' : 'reserve';

String participantRoleLabel(ParticipantRole r) =>
    r == ParticipantRole.starter ? 'Titular' : 'Reserva';
