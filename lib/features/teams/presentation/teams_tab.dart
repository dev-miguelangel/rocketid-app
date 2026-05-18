import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../data/teams_api.dart';
import '../domain/team.dart';
import 'team_detail_sheet.dart';
import 'team_logo.dart';
import 'team_widgets.dart';

/// Mínimo de caracteres para disparar la búsqueda de equipos en el backend.
const int _kTeamSearchMinChars = 3;

class TeamsTab extends ConsumerStatefulWidget {
  const TeamsTab({super.key});

  @override
  ConsumerState<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends ConsumerState<TeamsTab> {
  final _searchController = TextEditingController();
  String _query = '';
  String _searchTerm = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final term = value.trim();
      final next = term.length >= _kTeamSearchMinChars ? term : '';
      if (next != _searchTerm) setState(() => _searchTerm = next);
    });
  }

  bool get _isSearching => _searchTerm.length >= _kTeamSearchMinChars;

  String get _searchKey => _searchTerm.toLowerCase();

  bool _matches(Team t) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return t.name.toLowerCase().contains(q) ||
        t.sportLabel.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(myTeamsProvider);
    final searching = _isSearching;
    final partialQuery = !searching &&
        _query.trim().isNotEmpty &&
        _query.trim().length < _kTeamSearchMinChars;
    // IDs de equipos a los que ya pertenezco: se omiten de los resultados.
    final myTeamIds =
        teams.asData?.value.map((t) => t.id).toSet() ?? <String>{};

    return RefreshIndicator(
      color: AppColors.brandGreen,
      backgroundColor: AppColors.surfaceCard,
      onRefresh: () async {
        ref.invalidate(myTeamsProvider);
        if (searching) ref.invalidate(teamSearchProvider(_searchKey));
        await ref.read(myTeamsProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          TeamSearchField(
            controller: _searchController,
            hint: 'Buscar equipo...',
            onChanged: _onQueryChanged,
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
                  subtitle: 'Crea un equipo o postula a uno existente.',
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
          const SizedBox(height: 24),
          const TeamSectionLabel('DESCUBRIR EQUIPOS'),
          const SizedBox(height: 10),
          if (partialQuery)
            const TeamInfoCard(
              icon: Icons.search,
              text: 'Escribe al menos 3 caracteres para buscar equipos.',
            )
          else if (!searching)
            const TeamInfoCard(
              icon: Icons.travel_explore,
              text: 'Busca por nombre o deporte para postular a un equipo.',
            )
          else
            _SearchResults(
              searchKey: _searchKey,
              term: _searchTerm,
              myTeamIds: myTeamIds,
            ),
        ],
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.searchKey,
    required this.term,
    required this.myTeamIds,
  });

  final String searchKey;
  final String term;
  final Set<String> myTeamIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(teamSearchProvider(searchKey));
    return results.when(
      data: (list) {
        final available = list
            .where((t) => !myTeamIds.contains(t.id))
            .toList(growable: false);
        if (available.isEmpty) {
          return TeamInfoCard(
            icon: Icons.search_off,
            text: 'Sin equipos para "$term".',
          );
        }
        return Column(
          children: [
            for (var i = 0; i < available.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _TeamResultTile(team: available[i]),
            ],
          ],
        );
      },
      loading: () => const TeamLoadingCard(),
      error: (err, _) => TeamInlineErrorCard(
        error: err,
        onRetry: () => ref.invalidate(teamSearchProvider(searchKey)),
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

/// Tile de un equipo encontrado en la búsqueda, con acción para postular.
class _TeamResultTile extends ConsumerStatefulWidget {
  const _TeamResultTile({required this.team});

  final Team team;

  @override
  ConsumerState<_TeamResultTile> createState() => _TeamResultTileState();
}

class _TeamResultTileState extends ConsumerState<_TeamResultTile> {
  bool _saving = false;
  bool _requested = false;

  void _toast(String message) {
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

  Future<void> _apply() async {
    setState(() => _saving = true);
    try {
      await ref.read(teamsApiProvider).requestJoin(widget.team.id);
      if (!mounted) return;
      setState(() => _requested = true);
      _toast('Postulación enviada a "${widget.team.name}"');
    } on DioException catch (e) {
      _toast(teamErrorMessage(e));
    } catch (_) {
      _toast('No pudimos enviar la postulación');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.team;
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
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
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
          const SizedBox(width: 8),
          _ApplyButton(
            saving: _saving,
            requested: _requested,
            onPressed: (_saving || _requested) ? null : _apply,
          ),
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({
    required this.saving,
    required this.requested,
    required this.onPressed,
  });

  final bool saving;
  final bool requested;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (requested) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceChip,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderChip),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 16, color: AppColors.textMuted),
            SizedBox(width: 6),
            Text(
              'Postulado',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.black,
                ),
              )
            : const Text(
                'Postular',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}
