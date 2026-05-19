import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../data/activities_api.dart';
import '../domain/activity.dart';
import '../domain/activity_enums.dart';
import '../domain/activity_participant.dart';
import 'activity_widgets.dart';
import 'cupo_invite_sheet.dart';

/// Tablero visual para organizar los subequipos de un entrenamiento con
/// desafío interno.
///
/// Muestra dos columnas (una por subequipo) con cupos de titulares y reservas
/// según `playersPerSubteam` / `reservesPerSubteam`. Al abrirse, los
/// participantes sin subequipo se reparten al azar; el organizador puede luego
/// arrastrar a cualquiera entre cupos y equipos. Cada movimiento se persiste
/// con `POST /activities/:id/subteams/assign`.
class SubteamBoardScreen extends ConsumerStatefulWidget {
  const SubteamBoardScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<SubteamBoardScreen> createState() => _SubteamBoardScreenState();
}

class _SubteamBoardScreenState extends ConsumerState<SubteamBoardScreen> {
  /// Participantes ya ubicados en un cupo (con `subteam` y `participantRole`).
  /// `null` mientras no se ha inicializado el tablero.
  List<ActivityParticipant>? _board;

  /// Participantes que no alcanzaron cupo en la distribución inicial.
  int _overflow = 0;

  bool _distributing = false;
  bool _moving = false;
  bool _checkedInit = false;

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

  bool _isActive(ActivityParticipant p) =>
      p.status == ParticipantStatus.pending ||
      p.status == ParticipantStatus.invited ||
      p.status == ParticipantStatus.confirmed;

  Future<void> _initBoard(
    Activity activity,
    List<ActivityParticipant> participants,
  ) async {
    final active = participants.where(_isActive).toList();
    final placed = active
        .where((p) => p.subteam != null && p.participantRole != null)
        .toList();
    final unplaced = active
        .where((p) => p.subteam == null || p.participantRole == null)
        .toList();

    if (unplaced.isEmpty) {
      if (!mounted) return;
      setState(() {
        _board = placed;
        _overflow = 0;
      });
      return;
    }
    await _distribute(activity, placed, unplaced);
  }

  /// Reparte aleatoriamente a [unplaced] entre los cupos libres y persiste cada
  /// asignación.
  Future<void> _distribute(
    Activity activity,
    List<ActivityParticipant> placed,
    List<ActivityParticipant> unplaced,
  ) async {
    setState(() => _distributing = true);

    final players = activity.playersPerSubteam ?? 0;
    final reserves = activity.reservesPerSubteam ?? 0;

    int taken(Subteam s, ParticipantRole r) => placed
        .where((p) => p.subteam == s && p.participantRole == r)
        .length;
    int free(int cap, Subteam s, ParticipantRole r) =>
        max(0, cap - taken(s, r));

    final freeOneS = free(players, Subteam.one, ParticipantRole.starter);
    final freeTwoS = free(players, Subteam.two, ParticipantRole.starter);
    final freeOneR = free(reserves, Subteam.one, ParticipantRole.reserve);
    final freeTwoR = free(reserves, Subteam.two, ParticipantRole.reserve);

    // Lista de cupos libres, alternando equipo 1 / equipo 2 para balancear.
    final slots = <(Subteam, ParticipantRole)>[];
    for (var i = 0; i < max(freeOneS, freeTwoS); i++) {
      if (i < freeOneS) slots.add((Subteam.one, ParticipantRole.starter));
      if (i < freeTwoS) slots.add((Subteam.two, ParticipantRole.starter));
    }
    for (var i = 0; i < max(freeOneR, freeTwoR); i++) {
      if (i < freeOneR) slots.add((Subteam.one, ParticipantRole.reserve));
      if (i < freeTwoR) slots.add((Subteam.two, ParticipantRole.reserve));
    }

    final shuffled = [...unplaced]..shuffle();
    final api = ref.read(activitiesApiProvider);
    final result = <ActivityParticipant>[...placed];
    var overflow = 0;
    String? errorMsg;

    for (var i = 0; i < shuffled.length; i++) {
      if (i >= slots.length) {
        overflow++;
        continue;
      }
      final p = shuffled[i];
      final (sub, role) = slots[i];
      try {
        await api.assignSubteam(
          activity.id,
          userId: p.userId,
          subteam: sub,
          role: role,
        );
        result.add(p.copyWith(
          status: ParticipantStatus.confirmed,
          subteam: sub,
          participantRole: role,
        ));
      } on DioException catch (e) {
        errorMsg = activityErrorMessage(e);
        break;
      }
    }

    ref.invalidate(activityParticipantsProvider(widget.activityId));
    if (!mounted) return;
    setState(() {
      _distributing = false;
      _board = result;
      _overflow = overflow;
    });
    if (errorMsg != null) _notify(errorMsg);
  }

  /// Mueve a [dragged] al cupo `(destSub, destRole)`. Si el cupo está ocupado
  /// por [occupant], los intercambia.
  Future<void> _move(
    ActivityParticipant dragged,
    Subteam destSub,
    ParticipantRole destRole,
    ActivityParticipant? occupant,
  ) async {
    if (_moving) return;
    if (occupant != null && occupant.userId == dragged.userId) return;
    if (occupant == null &&
        dragged.subteam == destSub &&
        dragged.participantRole == destRole) {
      return;
    }
    final board = _board;
    if (board == null) return;

    final origSub = dragged.subteam!;
    final origRole = dragged.participantRole!;
    final snapshot = board;

    final updated = board.map((p) {
      if (p.userId == dragged.userId) {
        return p.copyWith(subteam: destSub, participantRole: destRole);
      }
      if (occupant != null && p.userId == occupant.userId) {
        return p.copyWith(subteam: origSub, participantRole: origRole);
      }
      return p;
    }).toList();

    setState(() {
      _board = updated;
      _moving = true;
    });

    final api = ref.read(activitiesApiProvider);
    try {
      await api.assignSubteam(
        widget.activityId,
        userId: dragged.userId,
        subteam: destSub,
        role: destRole,
      );
      if (occupant != null) {
        await api.assignSubteam(
          widget.activityId,
          userId: occupant.userId,
          subteam: origSub,
          role: origRole,
        );
      }
      ref.invalidate(activityParticipantsProvider(widget.activityId));
    } on DioException catch (e) {
      if (mounted) setState(() => _board = snapshot);
      _notify(activityErrorMessage(e));
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  Future<void> _inviteToCupo(Activity activity) async {
    final invited = await openCupoInviteSheet(context, activity: activity);
    if (invited == true && mounted) {
      // Hay nuevos invitados sin subequipo: recargar y redistribuir.
      setState(() {
        _board = null;
        _overflow = 0;
        _checkedInit = false;
      });
      ref.invalidate(activityParticipantsProvider(widget.activityId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(
      activityDetailProvider(widget.activityId),
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppTopBar.inner(title: 'Organizar equipos'),
      body: activityAsync.when(
        loading: () => const ActivityLoadingState(),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ActivityErrorState(
            onRetry: () =>
                ref.invalidate(activityDetailProvider(widget.activityId)),
          ),
        ),
        data: (activity) => _bodyForActivity(activity),
      ),
    );
  }

  Widget _bodyForActivity(Activity activity) {
    final isInternal = activity.type == ActivityType.training &&
        activity.trainingMode == TrainingMode.internalChallenge;
    final players = activity.playersPerSubteam ?? 0;
    final reserves = activity.reservesPerSubteam ?? 0;

    if (!isInternal || players + reserves == 0) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: ActivityEmptyState(
          icon: Icons.groups_outlined,
          title: 'Sin subequipos',
          subtitle: 'Esta actividad no organiza a sus participantes en '
              'subequipos.',
        ),
      );
    }

    final partsAsync = ref.watch(
      activityParticipantsProvider(widget.activityId),
    );

    return partsAsync.when(
      loading: () => const ActivityLoadingState(),
      error: (err, _) {
        if (err is DioException && err.response?.statusCode == 403) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: ActivityEmptyState(
              icon: Icons.lock_outline,
              title: 'Sin acceso',
              subtitle: 'Solo el organizador puede gestionar los subequipos.',
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ActivityErrorState(
            onRetry: () => ref.invalidate(
              activityParticipantsProvider(widget.activityId),
            ),
          ),
        );
      },
      data: (participants) {
        if (_board == null && !_checkedInit && !_distributing) {
          _checkedInit = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _initBoard(activity, participants);
          });
        }

        if (_distributing) {
          return const _DistributingState();
        }
        if (_board == null) {
          return const ActivityLoadingState();
        }
        return _buildBoard(activity, players, reserves);
      },
    );
  }

  Widget _buildBoard(Activity activity, int players, int reserves) {
    final board = _board!;

    List<ActivityParticipant> bucket(Subteam s, ParticipantRole r) =>
        board.where((p) => p.subteam == s && p.participantRole == r).toList()
          ..sort((a, b) => a.id.compareTo(b.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mantén presionado a un jugador y arrástralo para moverlo entre '
            'cupos y equipos.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          if (_overflow > 0) ...[
            const SizedBox(height: 12),
            _OverflowBanner(count: _overflow),
          ],
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _column(
                  activity,
                  Subteam.one,
                  players,
                  reserves,
                  bucket,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _column(
                  activity,
                  Subteam.two,
                  players,
                  reserves,
                  bucket,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _column(
    Activity activity,
    Subteam subteam,
    int players,
    int reserves,
    List<ActivityParticipant> Function(Subteam, ParticipantRole) bucket,
  ) {
    final starters = bucket(subteam, ParticipantRole.starter);
    final reserveList = bucket(subteam, ParticipantRole.reserve);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            subteamLabel(subteam),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < players; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _CupoSlot(
              occupant: i < starters.length ? starters[i] : null,
              busy: _moving,
              onAccept: (dragged) => _move(
                dragged,
                subteam,
                ParticipantRole.starter,
                i < starters.length ? starters[i] : null,
              ),
              onTapEmpty: () => _inviteToCupo(activity),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'RESERVA',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < reserves; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _CupoSlot(
              occupant: i < reserveList.length ? reserveList[i] : null,
              busy: _moving,
              onAccept: (dragged) => _move(
                dragged,
                subteam,
                ParticipantRole.reserve,
                i < reserveList.length ? reserveList[i] : null,
              ),
              onTapEmpty: () => _inviteToCupo(activity),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cupo (slot)
// ---------------------------------------------------------------------------

class _CupoSlot extends StatelessWidget {
  const _CupoSlot({
    required this.occupant,
    required this.busy,
    required this.onAccept,
    required this.onTapEmpty,
  });

  final ActivityParticipant? occupant;
  final bool busy;
  final void Function(ActivityParticipant dragged) onAccept;
  final VoidCallback onTapEmpty;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ActivityParticipant>(
      onWillAcceptWithDetails: (details) =>
          !busy && details.data.userId != occupant?.userId,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        final o = occupant;
        if (o == null) return _empty(hovering);
        return _filled(o);
      },
    );
  }

  Widget _empty(bool hovering) {
    return GestureDetector(
      onTap: busy ? null : onTapEmpty,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: hovering
              ? AppColors.brandGreen.withValues(alpha: 0.14)
              : AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hovering ? AppColors.brandGreen : AppColors.borderChip,
            width: hovering ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 15, color: AppColors.brandGreen),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'CUPO LIBRE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.brandGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filled(ActivityParticipant p) {
    final name = p.user?.displayName ?? 'Jugador';
    final card = _PlayerCard(name: name);
    return Draggable<ActivityParticipant>(
      data: p,
      maxSimultaneousDrags: busy ? 0 : 1,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 150,
          child: _PlayerCard(name: name, elevated: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.name, this.elevated = false});

  final String name;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceChip,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: elevated ? AppColors.brandGreen : AppColors.borderChip,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, size: 18, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            Icons.drag_indicator,
            size: 18,
            color: AppColors.textFaint,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estados auxiliares
// ---------------------------------------------------------------------------

class _DistributingState extends StatelessWidget {
  const _DistributingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.brandGreen,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Distribuyendo jugadores…',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverflowBanner extends StatelessWidget {
  const _OverflowBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.notificationDot.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.notificationDot,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 1
                  ? '1 jugador quedó sin cupo disponible.'
                  : '$count jugadores quedaron sin cupo disponible.',
              style: TextStyle(
                color: AppColors.textSoft,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
