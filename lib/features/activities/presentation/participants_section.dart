import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../data/activities_api.dart';
import '../domain/activity.dart';
import '../domain/activity_enums.dart';
import '../domain/activity_participant.dart';
import 'activity_widgets.dart';

/// Lista los participantes de una actividad.
///
/// El endpoint `GET /activities/:id/participants` solo es visible para el
/// organizador o el capitán; para el resto responde `403` y la sección se
/// oculta silenciosamente. Cuando [canManage] es `true` se muestran las
/// acciones de gestión por participante.
class ParticipantsSection extends ConsumerWidget {
  const ParticipantsSection({
    super.key,
    required this.activity,
    required this.canManage,
  });

  final Activity activity;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activityParticipantsProvider(activity.id));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: ActivityLoadingState(),
      ),
      error: (err, _) {
        if (err is DioException && err.response?.statusCode == 403) {
          return const SizedBox.shrink();
        }
        return ActivityErrorState(
          onRetry: () =>
              ref.invalidate(activityParticipantsProvider(activity.id)),
        );
      },
      data: (participants) {
        if (participants.isEmpty) {
          return const ActivityEmptyState(
            icon: Icons.group_outlined,
            title: 'Sin participantes',
            subtitle: 'Aún no hay personas inscritas en esta actividad.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < participants.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _ParticipantTile(
                participant: participants[i],
                activity: activity,
                canManage: canManage,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ParticipantTile extends ConsumerStatefulWidget {
  const _ParticipantTile({
    required this.participant,
    required this.activity,
    required this.canManage,
  });

  final ActivityParticipant participant;
  final Activity activity;
  final bool canManage;

  @override
  ConsumerState<_ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends ConsumerState<_ParticipantTile> {
  bool _busy = false;

  bool get _canResolve =>
      widget.canManage &&
      widget.activity.type == ActivityType.openCall &&
      widget.activity.openCallMode == OpenCallMode.public &&
      widget.participant.status == ParticipantStatus.pending;

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

  Future<void> _resolve(String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(activitiesApiProvider).resolveRegistration(
            widget.activity.id,
            widget.participant.userId,
            action,
          );
      ref.invalidate(activityParticipantsProvider(widget.activity.id));
      _notify(action == 'confirm'
          ? 'Solicitud confirmada'
          : 'Solicitud rechazada');
    } on DioException catch (e) {
      _notify(activityErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.participant;
    final name = p.user?.displayName ?? 'Usuario';
    final details = <String>[
      if (p.subteam != null) subteamLabel(p.subteam!),
      if (p.participantRole != null) participantRoleLabel(p.participantRole!),
      if (p.isExternal) 'Externo',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 20, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details.join(' · '),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ParticipantStatusChip(p.status),
            ],
          ),
          if (_canResolve) ...[
            const SizedBox(height: 10),
            if (_busy)
              SizedBox(
                height: 28,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brandGreen,
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _miniButton(
                      'Confirmar',
                      AppColors.brandGreen,
                      () => _resolve('confirm'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniButton(
                      'Rechazar',
                      AppColors.notificationDot,
                      () => _resolve('reject'),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _miniButton(String label, Color color, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

class _ParticipantStatusChip extends StatelessWidget {
  const _ParticipantStatusChip(this.status);

  final ParticipantStatus status;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    switch (status) {
      case ParticipantStatus.confirmed:
        fg = AppColors.brandGreen;
      case ParticipantStatus.pending:
      case ParticipantStatus.invited:
        fg = AppColors.textMuted;
      case ParticipantStatus.declined:
      case ParticipantStatus.cancelled:
        fg = AppColors.notificationDot;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        participantStatusLabel(status),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
