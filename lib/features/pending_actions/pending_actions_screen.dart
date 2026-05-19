import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_nav_handler.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../activities/presentation/activity_widgets.dart';
import 'domain/pending_action.dart';
import 'presentation/pending_action_tile.dart';

/// Vista de pendientes: lista plana de las acciones por resolver del usuario,
/// ordenada por fecha (más reciente primero).
class PendingActionsScreen extends ConsumerWidget {
  const PendingActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingActionsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppTopBar.inner(title: 'Pendientes'),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) => handleNavTap(context, i, currentIndex: 0),
      ),
      body: RefreshIndicator(
        color: AppColors.brandGreen,
        backgroundColor: AppColors.surfaceCard,
        onRefresh: () async {
          ref.invalidate(pendingActionsProvider);
          await ref.read(pendingActionsProvider.future);
        },
        child: pendingAsync.when(
          data: (inbox) => _PendingList(actions: inbox.actions),
          loading: () => ListView(
            children: const [ActivityLoadingState()],
          ),
          error: (_, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ActivityErrorState(
                onRetry: () => ref.invalidate(pendingActionsProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  const _PendingList({required this.actions});

  final List<PendingAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ActivityEmptyState(
            icon: Icons.check_circle_outline,
            title: 'Sin acciones pendientes',
            subtitle:
                'Cuando recibas invitaciones o solicitudes por resolver, '
                'aparecerán aquí.',
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: actions.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: PendingActionTile(action: actions[i]),
      ),
    );
  }
}
