import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_nav_handler.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../activities/domain/activity.dart';
import '../activities/domain/activity_enums.dart';
import '../activities/presentation/activity_form_sheet.dart';
import '../activities/presentation/activity_list_tile.dart';
import '../activities/presentation/activity_widgets.dart';
import '../auth/application/session_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionControllerProvider);
    final initial = switch (sessionState) {
      SessionAuthenticated(:final user) => _initialFromUser(
          user.name,
          user.email,
        ),
      _ => 'R',
    };

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppTopBar.dashboard(
        avatarInitial: initial,
        hasNotifications: true,
        onBellTap: () => _showSoon(context, 'Notificaciones'),
        onAvatarTap: () => context.push('/perfil'),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) => handleNavTap(
          context,
          i,
          currentIndex: 0,
          onCreateActivity: () => createActivityFlow(context, ref),
        ),
      ),
      body: const _DashboardBody(),
    );
  }

  static String _initialFromUser(String? name, String email) {
    final source = (name != null && name.trim().isNotEmpty) ? name : email;
    final ch = source.trim().isEmpty ? 'R' : source.trim()[0];
    return ch.toUpperCase();
  }

  static void _showSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label estará disponible pronto'),
          backgroundColor: AppColors.surfaceCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(myTeamsProvider);
    final teamsCount = teamsAsync.asData?.value.length;
    final teamsValue = teamsCount?.toString() ?? '—';
    final teamsCaption = switch (teamsCount) {
      null => 'cargando…',
      0 => 'sin equipos',
      1 => '1 equipo',
      _ => 'equipos activos',
    };

    final pendingAsync = ref.watch(pendingActionsProvider);
    final pendingCount = pendingAsync.asData?.value.total;
    final pendingValue = pendingCount?.toString() ?? '—';
    final pendingCaption = switch (pendingCount) {
      null => 'cargando…',
      0 => 'sin pendientes',
      1 => '1 acción',
      _ => 'acciones',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'PENDIENTES',
                  value: pendingValue,
                  caption: pendingCaption,
                  onTap: () => context.push('/pendientes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'EQUIPOS',
                  value: teamsValue,
                  caption: teamsCaption,
                  onTap: () => context.push('/contactos?tab=equipos'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _ActivityCard(),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: 152,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.brandGreen,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            caption,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard();

  /// Máximo de actividades listadas en el dashboard antes de enlazar a la agenda.
  static const _maxItems = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(myActivitiesProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: AppColors.brandGreen,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Mis actividades',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          activitiesAsync.when(
            loading: () => const ActivityLoadingState(),
            error: (_, _) => _ErrorBlock(
              onRetry: () => ref.invalidate(myActivitiesProvider),
            ),
            data: (list) => _content(context, list),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, List<Activity> list) {
    final now = DateTime.now();
    final upcoming = list
        .where((a) =>
            a.status != ActivityStatus.completed && a.endsAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    if (upcoming.isEmpty) return const _EmptyBlock();

    final visible = upcoming.take(_maxItems).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          ActivityListTile(activity: visible[i]),
        ],
        if (upcoming.length > _maxItems)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/agenda'),
              child: Text(
                'Ver todas en la agenda',
                style: TextStyle(
                  color: AppColors.brandGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Center(
          child: Icon(
            Icons.calendar_today_outlined,
            color: AppColors.textMuted.withValues(alpha: 0.7),
            size: 40,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'No tienes eventos ni actividades próximas',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Crea un evento o únete a uno existente.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'No pudimos cargar tus actividades',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(
            'Reintentar',
            style: TextStyle(
              color: AppColors.brandGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
