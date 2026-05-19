import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../data/activities_api.dart';
import '../domain/activity.dart';
import '../domain/activity_enums.dart';
import 'activity_form_sheet.dart';
import 'activity_widgets.dart';

/// Abre el bottom sheet de acciones rápidas para una [activity].
///
/// Las acciones disponibles dependen del tipo de actividad y de si el usuario
/// es el organizador. Replica la lógica de participación de `_ActionsCard`
/// (ver `activity_detail_screen.dart`).
Future<void> openActivityQuickActionsSheet(
  BuildContext context,
  Activity activity, {
  required bool isOrganizer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _QuickActionsSheet(
      activity: activity,
      isOrganizer: isOrganizer,
    ),
  );
}

class _QuickActionsSheet extends ConsumerStatefulWidget {
  const _QuickActionsSheet({required this.activity, required this.isOrganizer});

  final Activity activity;
  final bool isOrganizer;

  @override
  ConsumerState<_QuickActionsSheet> createState() => _QuickActionsSheetState();
}

class _QuickActionsSheetState extends ConsumerState<_QuickActionsSheet> {
  bool _busy = false;

  /// Ejecuta una acción de la API, refresca los providers y cierra el sheet.
  Future<void> _run(
    Future<void> Function(ActivitiesApi api) action,
    String successMessage,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await action(ref.read(activitiesApiProvider));
      ref.invalidate(myActivitiesProvider);
      ref.invalidate(agendaProvider);
      ref.invalidate(activityDetailProvider(widget.activity.id));
      ref.invalidate(activityParticipantsProvider(widget.activity.id));
      navigator.pop();
      _notify(messenger, successMessage);
    } on DioException catch (e) {
      _notify(messenger, activityErrorMessage(e));
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notify(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.surfaceCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<bool> _confirmCancel() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          'Cancelar actividad',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '¿Seguro que quieres cancelar esta actividad?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Volver',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Cancelar actividad',
              style: TextStyle(
                color: AppColors.notificationDot,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _openDetail() {
    Navigator.of(context).pop();
    context.push('/agenda/${widget.activity.id}');
  }

  Future<void> _edit() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop();
    final updated = await openActivityFormSheet(
      context,
      existing: widget.activity,
    );
    if (updated == null) return;
    ref.invalidate(myActivitiesProvider);
    ref.invalidate(agendaProvider);
    ref.invalidate(activityDetailProvider(widget.activity.id));
    _notify(messenger, 'Actividad actualizada');
  }

  Future<void> _cancelActivity() async {
    if (!await _confirmCancel()) return;
    await _run(
      (api) => api.cancel(widget.activity.id).then((_) {}),
      'Actividad cancelada',
    );
  }

  /// Acciones de participación según el tipo de actividad.
  List<_QuickAction> _participationActions() {
    final activity = widget.activity;
    final id = activity.id;
    switch (activity.type) {
      case ActivityType.openCall:
        if (activity.openCallMode == OpenCallMode.open ||
            activity.openCallMode == OpenCallMode.public) {
          return [
            // Sin cupos disponibles no se permite una nueva inscripción.
            if (!activity.isFull)
              _QuickAction(
                icon: Icons.how_to_reg,
                label: 'Inscribirme',
                onTap: () => _run(
                  (api) => api.register(id).then((_) {}),
                  'Inscripción enviada',
                ),
              ),
            _QuickAction(
              icon: Icons.logout,
              label: 'Retirarme',
              danger: true,
              onTap: () => _run(
                (api) => api.withdraw(id),
                'Te retiraste de la actividad',
              ),
            ),
          ];
        }
        if (activity.openCallMode == OpenCallMode.private) {
          return [
            _QuickAction(
              icon: Icons.check_circle_outline,
              label: 'Aceptar invitación',
              onTap: () => _run(
                (api) => api.acceptInvitation(id).then((_) {}),
                'Invitación aceptada',
              ),
            ),
            _QuickAction(
              icon: Icons.cancel_outlined,
              label: 'Rechazar invitación',
              danger: true,
              onTap: () => _run(
                (api) => api.declineInvitation(id).then((_) {}),
                'Invitación rechazada',
              ),
            ),
          ];
        }
        return const [];
      case ActivityType.training:
        return [
          _QuickAction(
            icon: Icons.check_circle_outline,
            label: 'Confirmar asistencia',
            onTap: () => _run(
              (api) => api.confirmAttendance(id).then((_) {}),
              'Asistencia confirmada',
            ),
          ),
          _QuickAction(
            icon: Icons.cancel_outlined,
            label: 'Declinar asistencia',
            danger: true,
            onTap: () => _run(
              (api) => api.declineAttendance(id).then((_) {}),
              'Asistencia declinada',
            ),
          ),
        ];
      case ActivityType.challenge:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;

    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.open_in_new,
        label: 'Ver detalle',
        onTap: _openDetail,
      ),
    ];
    String? hint;

    if (activity.isCancelled) {
      hint = 'Esta actividad fue cancelada.';
    } else if (widget.isOrganizer) {
      actions.add(_QuickAction(
        icon: Icons.edit_outlined,
        label: 'Editar actividad',
        onTap: _edit,
      ));
      actions.add(_QuickAction(
        icon: Icons.cancel_outlined,
        label: 'Cancelar actividad',
        danger: true,
        onTap: _cancelActivity,
      ));
    } else {
      final participation = _participationActions();
      if (participation.isEmpty) {
        hint = 'La participación en esta actividad la gestiona el organizador.';
      } else {
        actions.addAll(participation);
        if (activity.isFull) {
          hint = 'No hay cupos disponibles para inscribirse.';
        }
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderChip,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.displayTitle,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ActivityTypeChip(activity.type),
                      const SizedBox(width: 8),
                      ActivityStatusChip(activity.status),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: AppColors.borderSubtle, height: 1),
            if (_busy)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brandGreen,
                    ),
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 6),
              for (final action in actions) _ActionTile(action: action),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Text(
                    hint,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Descripción de una acción del sheet.
class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final color =
        action.danger ? AppColors.notificationDot : AppColors.textPrimary;
    return ListTile(
      onTap: action.onTap,
      leading: Icon(action.icon, size: 22, color: color),
      title: Text(
        action.label,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
