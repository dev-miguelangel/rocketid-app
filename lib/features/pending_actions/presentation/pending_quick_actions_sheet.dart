import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../activities/data/activities_api.dart';
import '../../teams/data/teams_api.dart';
import '../domain/pending_action.dart';

/// Abre el bottom sheet de acciones rápidas para una acción pendiente.
///
/// Replica la lógica de iconos de `activity_quick_actions_sheet.dart`: las
/// acciones disponibles dependen del tipo de pendiente ([PendingActionKind]).
Future<void> openPendingQuickActionsSheet(
  BuildContext context,
  PendingAction action,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _PendingQuickActionsSheet(action: action),
  );
}

class _PendingQuickActionsSheet extends ConsumerStatefulWidget {
  const _PendingQuickActionsSheet({required this.action});

  final PendingAction action;

  @override
  ConsumerState<_PendingQuickActionsSheet> createState() =>
      _PendingQuickActionsSheetState();
}

class _PendingQuickActionsSheetState
    extends ConsumerState<_PendingQuickActionsSheet> {
  bool _busy = false;

  /// Ejecuta una acción de la API, refresca los providers y cierra el sheet.
  Future<void> _run(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await action();
      ref.invalidate(pendingActionsProvider);
      ref.invalidate(myActivitiesProvider);
      ref.invalidate(agendaProvider);
      ref.invalidate(teamRequestsProvider);
      ref.invalidate(teamMembersProvider);
      navigator.pop();
      _notify(messenger, successMessage);
    } on DioException catch (e) {
      _notify(messenger, _errorMessage(e));
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Traduce el error según el flujo que resuelve la acción.
  String _errorMessage(DioException e) {
    return widget.action.kind == PendingActionKind.teamJoinRequest
        ? teamErrorMessage(e)
        : activityErrorMessage(e);
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

  void _openActivity() {
    final id = widget.action.activityId;
    if (id == null) return;
    Navigator.of(context).pop();
    context.push('/agenda/$id');
  }

  /// Acciones según el tipo de pendiente. Mismos iconos que el sheet de
  /// actividades (`activity_quick_actions_sheet.dart`).
  List<_QuickAction> _actions() {
    final action = widget.action;
    final activitiesApi = ref.read(activitiesApiProvider);
    final teamsApi = ref.read(teamsApiProvider);
    final activityId = action.activityId;
    final teamId = action.teamId;
    final userId = action.requesterUserId;

    switch (action.kind) {
      case PendingActionKind.activityInvitation:
        return [
          _QuickAction(
            icon: Icons.check_circle_outline,
            label: 'Aceptar invitación',
            onTap: () => _run(
              () => activitiesApi.acceptInvitation(activityId!).then((_) {}),
              'Invitación aceptada',
            ),
          ),
          _QuickAction(
            icon: Icons.cancel_outlined,
            label: 'Rechazar invitación',
            danger: true,
            onTap: () => _run(
              () => activitiesApi.declineInvitation(activityId!).then((_) {}),
              'Invitación rechazada',
            ),
          ),
        ];
      case PendingActionKind.trainingConvocation:
        return [
          _QuickAction(
            icon: Icons.check_circle_outline,
            label: 'Confirmar asistencia',
            onTap: () => _run(
              () => activitiesApi.confirmAttendance(activityId!).then((_) {}),
              'Asistencia confirmada',
            ),
          ),
          _QuickAction(
            icon: Icons.cancel_outlined,
            label: 'Declinar asistencia',
            danger: true,
            onTap: () => _run(
              () => activitiesApi.declineAttendance(activityId!).then((_) {}),
              'Asistencia declinada',
            ),
          ),
        ];
      case PendingActionKind.teamJoinRequest:
        return [
          _QuickAction(
            icon: Icons.check_circle_outline,
            label: 'Aceptar solicitud',
            onTap: () => _run(
              () => teamsApi.acceptRequest(teamId!, userId!),
              'Solicitud aceptada',
            ),
          ),
          _QuickAction(
            icon: Icons.cancel_outlined,
            label: 'Rechazar solicitud',
            danger: true,
            onTap: () => _run(
              () => teamsApi.rejectRequest(teamId!, userId!),
              'Solicitud rechazada',
            ),
          ),
        ];
      case PendingActionKind.activityRegistrationRequest:
        return [
          _QuickAction(
            icon: Icons.how_to_reg,
            label: 'Aprobar inscripción',
            onTap: () => _run(
              () => activitiesApi
                  .resolveRegistration(activityId!, userId!, 'confirm')
                  .then((_) {}),
              'Inscripción aprobada',
            ),
          ),
          _QuickAction(
            icon: Icons.cancel_outlined,
            label: 'Rechazar inscripción',
            danger: true,
            onTap: () => _run(
              () => activitiesApi
                  .resolveRegistration(activityId!, userId!, 'reject')
                  .then((_) {}),
              'Inscripción rechazada',
            ),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final actions = _actions();
    if (action.activityId != null) {
      actions.add(_QuickAction(
        icon: Icons.open_in_new,
        label: 'Ver actividad',
        onTap: _openActivity,
      ));
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
                    action.title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _KindPill(kind: action.kind),
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
            ],
          ],
        ),
      ),
    );
  }
}

/// Chip de tipo de pendiente, reutilizado en el encabezado del sheet.
class _KindPill extends StatelessWidget {
  const _KindPill({required this.kind});

  final PendingActionKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        kind.chipLabel,
        style: TextStyle(
          color: AppColors.brandGreen,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
