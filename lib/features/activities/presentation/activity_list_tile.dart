import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../auth/application/session_state.dart';
import '../domain/activity.dart';
import '../domain/activity_enums.dart';
import 'activity_quick_actions_sheet.dart';
import 'activity_widgets.dart';

/// Ítem de actividad reutilizable para listas (dashboard "Mis actividades" y
/// agenda). Muestra tipo, deporte, título, horario, organizador, equipos,
/// cupos y la cuenta atrás de inscripción, delimitado con un borde superior e
/// inferior, y un botón de acciones rápidas.
class ActivityListTile extends ConsumerWidget {
  const ActivityListTile({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final currentUserId = switch (session) {
      SessionAuthenticated(:final user) => user.id,
      _ => null,
    };
    final isOrganizer =
        currentUserId != null && activity.organizerId == currentUserId;

    final organizer = _organizerLabel();
    final teams = _teamsLabel();
    final showCountdown = activity.requiresRegistration &&
        activity.registrationDeadline != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/agenda/${activity.id}'),
        child: Container(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ActivityTypeChip(activity.type),
                  if (activity.sport != null) ...[
                    const SizedBox(width: 8),
                    SportChip(activity.sport!),
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: () => openActivityQuickActionsSheet(
                      context,
                      activity,
                      isOrganizer: isOrganizer,
                    ),
                    tooltip: 'Acciones rápidas',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.bolt),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.brandGreen,
                      backgroundColor:
                          AppColors.brandGreen.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                activity.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _MetaRow(icon: Icons.schedule, text: _scheduleLabel()),
              if (organizer.isNotEmpty) ...[
                const SizedBox(height: 4),
                _MetaRow(icon: Icons.person_outline, text: organizer),
              ],
              if (teams != null) ...[
                const SizedBox(height: 4),
                _MetaRow(icon: Icons.groups_outlined, text: teams),
              ],
              ..._spotsWidgets(),
              if (showCountdown) ...[
                const SizedBox(height: 8),
                _RegistrationCountdown(
                  deadline: activity.registrationDeadline!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Etiqueta del organizador: usa el alias (`organizer_alias` de la API).
  String _organizerLabel() {
    final alias =
        (activity.organizerAlias ?? activity.organizer?.alias)?.trim();
    return (alias != null && alias.isNotEmpty) ? 'Organiza @$alias' : '';
  }

  /// Equipos involucrados según el tipo de actividad, o `null` si no aplica.
  String? _teamsLabel() {
    switch (activity.type) {
      case ActivityType.challenge:
        final one = activity.teamOne?.name.trim();
        final two = activity.teamTwo?.name.trim();
        if ((one == null || one.isEmpty) && (two == null || two.isEmpty)) {
          return null;
        }
        final left = (one != null && one.isNotEmpty) ? one : 'Equipo 1';
        final right = (two != null && two.isNotEmpty) ? two : 'Equipo 2';
        return '$left vs $right';
      case ActivityType.training:
        final t = activity.team?.name.trim();
        return (t == null || t.isEmpty) ? null : 'Equipo: $t';
      case ActivityType.openCall:
        return null;
    }
  }

  /// Inicio y fin: un solo día usa el rango horario; varios días muestra ambas
  /// fechas.
  String _scheduleLabel() {
    final start = activity.startsAt.toLocal();
    final end = activity.endsAt.toLocal();
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) {
      return '${activityDayHeaderLabel(activity.startsAt)} · '
          '${activityTimeRange(activity.startsAt, activity.endsAt)}';
    }
    return '${activityShortDate(activity.startsAt)} '
        '${activityTimeLabel(activity.startsAt)} – '
        '${activityShortDate(activity.endsAt)} '
        '${activityTimeLabel(activity.endsAt)}';
  }

  /// Información de cupos: un badge con disponibles para actividades con cupo
  /// máximo, o el número de confirmados cuando no hay límite.
  List<Widget> _spotsWidgets() {
    final max = activity.maxParticipants;
    if (max != null && max > 0) {
      return [
        const SizedBox(height: 8),
        _SpotsBadge(
          used: activity.usedSpots,
          max: max,
          available: activity.availableSpots ?? (max - activity.usedSpots),
        ),
      ];
    }
    if (activity.usedSpots > 0) {
      return [
        const SizedBox(height: 4),
        _MetaRow(
          icon: Icons.groups,
          text: '${activity.usedSpots} confirmados',
        ),
      ];
    }
    return const [];
  }
}

/// Badge de cupos: muestra disponibles y total, en rojo cuando está completo.
class _SpotsBadge extends StatelessWidget {
  const _SpotsBadge({
    required this.used,
    required this.max,
    required this.available,
  });

  final int used;
  final int max;
  final int available;

  @override
  Widget build(BuildContext context) {
    final full = available <= 0;
    final color = full ? AppColors.notificationDot : AppColors.brandGreen;
    final text = full
        ? 'Sin cupos disponibles · $used/$max'
        : '$available ${available == 1 ? 'cupo disponible' : 'cupos disponibles'}'
            ' · $used/$max';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            full ? Icons.event_busy : Icons.event_available,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

/// Cuenta atrás en vivo hasta el cierre de la inscripción.
class _RegistrationCountdown extends StatefulWidget {
  const _RegistrationCountdown({required this.deadline});

  final DateTime deadline;

  @override
  State<_RegistrationCountdown> createState() => _RegistrationCountdownState();
}

class _RegistrationCountdownState extends State<_RegistrationCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.deadline.difference(DateTime.now());
    final closed = remaining.isNegative;
    final urgent = !closed && remaining.inHours < 24;
    final color = (closed || urgent)
        ? AppColors.notificationDot
        : AppColors.brandGreen;
    final text = closed
        ? 'Inscripción cerrada'
        : 'Inscripción cierra en ${_format(remaining)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            closed ? Icons.lock_clock : Icons.hourglass_bottom,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static String _format(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }
}
