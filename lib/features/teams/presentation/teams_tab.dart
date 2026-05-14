import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../domain/team.dart';
import 'team_detail_sheet.dart';
import 'team_logo.dart';
import 'team_widgets.dart';

class TeamsTab extends ConsumerStatefulWidget {
  const TeamsTab({super.key});

  @override
  ConsumerState<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends ConsumerState<TeamsTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(Team t) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return t.name.toLowerCase().contains(q) ||
        t.sportLabel.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(myTeamsProvider);

    return RefreshIndicator(
      color: AppColors.brandGreen,
      backgroundColor: AppColors.surfaceCard,
      onRefresh: () async {
        ref.invalidate(myTeamsProvider);
        await ref.read(myTeamsProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          TeamSearchField(
            controller: _searchController,
            hint: 'Buscar equipo...',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 16),
          const TeamSectionLabel('MIS EQUIPOS'),
          const SizedBox(height: 10),
          teams.when(
            data: (list) {
              if (list.isEmpty) {
                return const TeamEmptyCard(
                  icon: Icons.diversity_3_outlined,
                  title: 'Sin equipos aún',
                  subtitle: 'Crea un equipo para empezar a colaborar.',
                );
              }
              final filtered = list.where(_matches).toList(growable: false);
              if (filtered.isEmpty) {
                return const TeamInfoCard(
                  icon: Icons.search_off,
                  text: 'Sin equipos para esa búsqueda.',
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < filtered.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _TeamTile(team: filtered[i]),
                  ],
                ],
              );
            },
            loading: () => const TeamLoadingCard(),
            error: (err, _) => TeamInlineErrorCard(
              error: err,
              onRetry: () => ref.invalidate(myTeamsProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamTile extends ConsumerWidget {
  const _TeamTile({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitleParts = <String>[
      if (team.sportLabel.isNotEmpty) team.sportLabel,
      genderLabel(team.gender),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () async {
            final result = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => TeamDetailSheet(teamId: team.id, initial: team),
            );
            if (!context.mounted) return;
            if (result == 'deleted' || result == 'left') {
              ref.invalidate(myTeamsProvider);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      result == 'deleted'
                          ? 'Equipo "${team.name}" eliminado'
                          : 'Saliste de "${team.name}"',
                    ),
                    backgroundColor: AppColors.surfaceCard,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            } else if (result == 'updated') {
              ref.invalidate(myTeamsProvider);
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                TeamLogo(icon: team.icon, colorHex: team.color, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleParts.join(' · '),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
