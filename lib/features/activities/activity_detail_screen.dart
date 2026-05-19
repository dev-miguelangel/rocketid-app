import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../auth/application/session_state.dart';
import 'data/activities_api.dart';
import 'domain/activity.dart';
import 'domain/activity_enums.dart';
import 'presentation/activity_form_sheet.dart';
import 'presentation/activity_widgets.dart';
import 'presentation/invite_participants_sheet.dart';
import 'presentation/participants_section.dart';

/// Detalle de una actividad: información, acciones de participación y, para el
/// organizador, la lista de participantes.
class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activityDetailProvider(activityId));
    final session = ref.watch(sessionControllerProvider);
    final currentUserId = switch (session) {
      SessionAuthenticated(:final user) => user.id,
      _ => null,
    };

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppTopBar.inner(title: 'Actividad'),
      body: async.when(
        loading: () => const ActivityLoadingState(),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ActivityErrorState(
            onRetry: () => ref.invalidate(activityDetailProvider(activityId)),
          ),
        ),
        data: (activity) => _DetailBody(
          activity: activity,
          isOrganizer: currentUserId != null &&
              currentUserId == activity.organizerId,
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.activity, required this.isOrganizer});

  final Activity activity;
  final bool isOrganizer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            ActivityTypeChip(activity.type),
            const SizedBox(width: 8),
            ActivityStatusChip(activity.status),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          activity.displayTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (activity.description != null &&
            activity.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            activity.description!.trim(),
            style: TextStyle(
              color: AppColors.textSoft,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 20),
        _Section(
          title: 'Cuándo',
          children: [
            _InfoRow(
              icon: Icons.event,
              text: activityDayHeaderLabel(activity.startsAt),
            ),
            _InfoRow(
              icon: Icons.schedule,
              text: activityTimeRange(activity.startsAt, activity.endsAt),
            ),
            if (activity.requiresRegistration &&
                activity.registrationDeadline != null)
              _InfoRow(
                icon: Icons.how_to_reg,
                text: 'Inscripción hasta el '
                    '${activityShortDate(activity.registrationDeadline!)} '
                    '${activityTimeLabel(activity.registrationDeadline!)}',
              ),
          ],
        ),
        _Section(
          title: 'Detalles',
          children: [
            if (activity.sport != null)
              _InfoRow(
                icon: Icons.sports,
                text: activity.sport!.displayLabel,
              ),
            if (activity.organizer != null)
              _InfoRow(
                icon: Icons.person_outline,
                text: 'Organiza ${activity.organizer!.displayName}',
              ),
            ..._typeSpecificRows(),
          ],
        ),
        _Section(
          title: 'Lugar',
          children: [
            if (activity.locationInstructions != null &&
                activity.locationInstructions!.trim().isNotEmpty)
              _InfoRow(
                icon: Icons.place_outlined,
                text: activity.locationInstructions!.trim(),
              ),
            _InfoRow(
              icon: Icons.my_location,
              text: '${activity.latitude.toStringAsFixed(5)}, '
                  '${activity.longitude.toStringAsFixed(5)}',
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: () => _openMap(context, activity),
                icon: const Icon(Icons.map_outlined, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandGreen,
                  side: BorderSide(color: AppColors.borderChip),
                ),
                label: const Text('Ver en el mapa'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!isOrganizer)
          _ActionsCard(activity: activity)
        else ...[
          _OrganizerActions(activity: activity),
          const SizedBox(height: 16),
          Text(
            'Participantes',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ParticipantsSection(activity: activity, canManage: true),
        ],
      ],
    );
  }

  List<Widget> _typeSpecificRows() {
    switch (activity.type) {
      case ActivityType.challenge:
        return [
          if (activity.teamOne != null)
            _InfoRow(
              icon: Icons.shield_outlined,
              text: 'Equipo 1: ${activity.teamOne!.name}',
            ),
          if (activity.teamTwo != null)
            _InfoRow(
              icon: Icons.shield_outlined,
              text: 'Equipo 2: ${activity.teamTwo!.name}',
            ),
        ];
      case ActivityType.training:
        return [
          if (activity.team != null)
            _InfoRow(
              icon: Icons.groups_outlined,
              text: 'Equipo: ${activity.team!.name}',
            ),
          if (activity.trainingMode != null)
            _InfoRow(
              icon: Icons.tune,
              text: 'Modalidad: ${trainingModeLabel(activity.trainingMode!)}',
            ),
          if (activity.trainingMode == TrainingMode.internalChallenge) ...[
            if (activity.playersPerSubteam != null)
              _InfoRow(
                icon: Icons.person,
                text: 'Jugadores por subequipo: '
                    '${activity.playersPerSubteam}',
              ),
            if (activity.reservesPerSubteam != null)
              _InfoRow(
                icon: Icons.person_add_alt,
                text: 'Reservas por subequipo: '
                    '${activity.reservesPerSubteam}',
              ),
            _InfoRow(
              icon: Icons.public,
              text: activity.allowExternals
                  ? 'Permite participantes externos'
                  : 'Solo miembros del equipo',
            ),
          ],
        ];
      case ActivityType.openCall:
        return [
          if (activity.openCallMode != null)
            _InfoRow(
              icon: Icons.campaign_outlined,
              text: 'Modalidad: '
                  '${openCallModeLabel(activity.openCallMode!)}',
            ),
          if (activity.maxParticipants != null)
            _InfoRow(
              icon: Icons.groups,
              text: 'Cupos: ${activity.usedSpots}/${activity.maxParticipants}'
                  ' · ${activity.availableSpots ?? (activity.maxParticipants! - activity.usedSpots)}'
                  ' disponibles',
            ),
        ];
    }
  }

  Future<void> _openMap(BuildContext context, Activity activity) async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${activity.latitude}'
      '&mlon=${activity.longitude}'
      '#map=16/${activity.latitude}/${activity.longitude}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el mapa'),
            backgroundColor: AppColors.surfaceCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Acciones de participación
// ---------------------------------------------------------------------------

class _ActionsCard extends ConsumerStatefulWidget {
  const _ActionsCard({required this.activity});

  final Activity activity;

  @override
  ConsumerState<_ActionsCard> createState() => _ActionsCardState();
}

class _ActionsCardState extends ConsumerState<_ActionsCard> {
  bool _busy = false;

  Future<void> _run(
    Future<void> Function(ActivitiesApi api) action,
    String successMessage,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action(ref.read(activitiesApiProvider));
      ref.invalidate(activityDetailProvider(widget.activity.id));
      ref.invalidate(activityParticipantsProvider(widget.activity.id));
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.surfaceCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } on DioException catch (e) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(activityErrorMessage(e)),
            backgroundColor: AppColors.surfaceCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    if (activity.isCancelled) {
      return const _OrganizerBadge(
        icon: Icons.cancel_outlined,
        text: 'Esta actividad fue cancelada.',
      );
    }

    final id = activity.id;
    final buttons = <Widget>[];

    if (activity.type == ActivityType.openCall) {
      if (activity.openCallMode == OpenCallMode.open ||
          activity.openCallMode == OpenCallMode.public) {
        // Sin cupos disponibles no se permite una nueva inscripción.
        if (!activity.isFull) {
          buttons.add(_primary(
            'Inscribirme',
            () => _run((api) => api.register(id).then((_) {}),
                'Inscripción enviada'),
          ));
        }
        buttons.add(_secondary(
          'Retirarme',
          () => _run((api) => api.withdraw(id), 'Te retiraste de la actividad'),
        ));
      } else if (activity.openCallMode == OpenCallMode.private) {
        buttons.add(_primary(
          'Aceptar invitación',
          () => _run((api) => api.acceptInvitation(id).then((_) {}),
              'Invitación aceptada'),
        ));
        buttons.add(_secondary(
          'Rechazar invitación',
          () => _run((api) => api.declineInvitation(id).then((_) {}),
              'Invitación rechazada'),
        ));
      }
    } else if (activity.type == ActivityType.training) {
      buttons.add(_primary(
        'Confirmar asistencia',
        () => _run((api) => api.confirmAttendance(id).then((_) {}),
            'Asistencia confirmada'),
      ));
      buttons.add(_secondary(
        'Declinar asistencia',
        () => _run((api) => api.declineAttendance(id).then((_) {}),
            'Asistencia declinada'),
      ));
    }

    if (buttons.isEmpty) {
      return const _OrganizerBadge(
        icon: Icons.info_outline,
        text: 'La participación en esta actividad la gestiona el organizador.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activity.isFull) ...[
          const _OrganizerBadge(
            icon: Icons.event_busy,
            text: 'No hay cupos disponibles para esta actividad.',
          ),
          const SizedBox(height: 10),
        ],
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          buttons[i],
        ],
      ],
    );
  }

  Widget _primary(String label, VoidCallback onTap) {
    return FilledButton(
      onPressed: _busy ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandGreen,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(50),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
      child: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
          : Text(label),
    );
  }

  Widget _secondary(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: _busy ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: BorderSide(color: AppColors.borderChip),
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

// ---------------------------------------------------------------------------
// Gestión del organizador
// ---------------------------------------------------------------------------

class _OrganizerActions extends ConsumerStatefulWidget {
  const _OrganizerActions({required this.activity});

  final Activity activity;

  @override
  ConsumerState<_OrganizerActions> createState() => _OrganizerActionsState();
}

class _OrganizerActionsState extends ConsumerState<_OrganizerActions> {
  bool _busy = false;

  bool get _canInvite {
    final a = widget.activity;
    return a.openCallMode == OpenCallMode.private ||
        (a.type == ActivityType.training &&
            a.trainingMode == TrainingMode.internalChallenge &&
            a.allowExternals);
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.surfaceCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          title,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          message,
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Confirmar',
              style: TextStyle(
                color: AppColors.brandGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _edit() async {
    final updated = await openActivityFormSheet(
      context,
      existing: widget.activity,
    );
    if (updated != null) _notify('Actividad actualizada');
  }

  Future<void> _invite() async {
    final ok = await openInviteParticipantsSheet(context, widget.activity.id);
    if (ok == true) _notify('Invitaciones enviadas');
  }

  Future<void> _cancelActivity() async {
    if (!await _confirm(
      'Cancelar actividad',
      '¿Seguro que quieres cancelar esta actividad?',
    )) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(activitiesApiProvider).cancel(widget.activity.id);
      ref.invalidate(activityDetailProvider(widget.activity.id));
      ref.invalidate(agendaProvider);
      ref.invalidate(myActivitiesProvider);
      _notify('Actividad cancelada');
    } on DioException catch (e) {
      _notify(activityErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteActivity() async {
    if (!await _confirm(
      'Eliminar actividad',
      'Esta acción no se puede deshacer. ¿Eliminar la actividad?',
    )) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(activitiesApiProvider).delete(widget.activity.id);
      ref.invalidate(agendaProvider);
      ref.invalidate(myActivitiesProvider);
      if (!mounted) return;
      _notify('Actividad eliminada');
      context.pop();
    } on DioException catch (e) {
      _notify(activityErrorMessage(e));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cancelled = widget.activity.isCancelled;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined,
                  size: 18, color: AppColors.brandGreen),
              SizedBox(width: 8),
              Text(
                'Gestión del organizador',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_busy)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.brandGreen,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _action(Icons.edit_outlined, 'Editar', _edit),
                if (widget.activity.type == ActivityType.training &&
                    widget.activity.trainingMode ==
                        TrainingMode.internalChallenge)
                  _action(
                    Icons.dashboard_customize_outlined,
                    'Organizar equipos',
                    () => context.push(
                      '/agenda/${widget.activity.id}/equipos',
                    ),
                  ),
                if (_canInvite)
                  _action(Icons.person_add_alt, 'Invitar', _invite),
                if (!cancelled)
                  _action(
                    Icons.cancel_outlined,
                    'Cancelar',
                    _cancelActivity,
                  ),
                _action(
                  Icons.delete_outline,
                  'Eliminar',
                  _deleteActivity,
                  danger: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _action(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final color = danger ? AppColors.notificationDot : AppColors.textSecondary;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: AppColors.borderChip),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OrganizerBadge extends StatelessWidget {
  const _OrganizerBadge({
    this.icon = Icons.verified_outlined,
    this.text = 'Eres el organizador de esta actividad.',
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.brandGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSoft,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bloques de presentación
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSoft,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
