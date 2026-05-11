import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_top_bar.dart';
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
        onTap: (i) {
          if (i == 0) return;
          if (i == 4) {
            context.push('/perfil');
            return;
          }
          _showSoon(context, 'Esta sección');
        },
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

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'EVENTOS',
                  value: '0',
                  caption: 'este mes',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'EQUIPOS',
                  value: '—',
                  caption: 'sin equipos',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _ActivityCard(),
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
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.brandGreen,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            caption,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
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
              const Icon(
                Icons.show_chart,
                color: AppColors.brandGreen,
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                'Mi actividad',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.7),
              size: 40,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No tienes eventos ni actividades próximas',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Crea un evento o únete a uno existente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
