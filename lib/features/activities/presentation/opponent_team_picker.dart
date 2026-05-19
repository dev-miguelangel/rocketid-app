import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../teams/domain/team.dart';
import 'activity_form_fields.dart';

/// Selector del equipo rival de un desafío: busca equipos por nombre y muestra
/// solo los del mismo deporte que el equipo 1, excluyendo al propio equipo 1.
class OpponentTeamPicker extends ConsumerStatefulWidget {
  const OpponentTeamPicker({
    super.key,
    required this.value,
    required this.sportId,
    required this.excludeTeamId,
    required this.enabled,
    required this.onChanged,
  });

  /// Equipo rival ya elegido (o `null`).
  final Team? value;

  /// Deporte del equipo 1; si es `null`, el selector se muestra deshabilitado.
  final int? sportId;

  /// Id del equipo 1, para excluirlo de los resultados.
  final String? excludeTeamId;

  final bool enabled;
  final ValueChanged<Team?> onChanged;

  @override
  ConsumerState<OpponentTeamPicker> createState() => _OpponentTeamPickerState();
}

class _OpponentTeamPickerState extends ConsumerState<OpponentTeamPicker> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value;
    if (selected != null) {
      return _SelectedTile(
        team: selected,
        enabled: widget.enabled,
        onClear: () {
          _search.clear();
          setState(() => _query = '');
          widget.onChanged(null);
        },
      );
    }

    if (widget.sportId == null) {
      return InputDecorator(
        decoration: activityFieldDecoration(icon: Icons.shield_outlined),
        child: Text(
          'Selecciona primero el equipo 1',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          enabled: widget.enabled,
          onChanged: _onChanged,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
          cursorColor: AppColors.brandGreen,
          decoration: activityFieldDecoration(
            hint: 'Busca el equipo rival por nombre',
            icon: Icons.search,
          ),
        ),
        if (_query.length >= 2) ...[
          const SizedBox(height: 8),
          _Results(
            query: _query,
            sportId: widget.sportId!,
            excludeTeamId: widget.excludeTeamId,
            onPick: (team) {
              _search.clear();
              setState(() => _query = '');
              widget.onChanged(team);
            },
          ),
        ],
      ],
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({
    required this.query,
    required this.sportId,
    required this.excludeTeamId,
    required this.onPick,
  });

  final String query;
  final int sportId;
  final String? excludeTeamId;
  final ValueChanged<Team> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamSearchProvider(query));
    return async.when(
      loading: () => _box(
        Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.brandGreen,
            ),
          ),
        ),
      ),
      error: (_, _) => _box(
        Text(
          'No pudimos buscar equipos',
          style: TextStyle(color: AppColors.notificationDot, fontSize: 13),
        ),
      ),
      data: (teams) {
        final filtered = teams
            .where((t) => t.sportId == sportId && t.id != excludeTeamId)
            .toList(growable: false);
        if (filtered.isEmpty) {
          return _box(
            Text(
              'Sin equipos de este deporte con ese nombre',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          );
        }
        return Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            color: AppColors.surfaceChip,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderChip),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: AppColors.borderSubtle,
            ),
            itemBuilder: (context, i) {
              final t = filtered[i];
              return ListTile(
                dense: true,
                leading: Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: AppColors.brandGreen,
                ),
                title: Text(
                  t.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: t.sportLabel.isEmpty
                    ? null
                    : Text(
                        t.sportLabel,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                onTap: () => onPick(t),
              );
            },
          ),
        );
      },
    );
  }

  Widget _box(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceChip,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderChip),
      ),
      child: Center(child: child),
    );
  }
}

class _SelectedTile extends StatelessWidget {
  const _SelectedTile({
    required this.team,
    required this.enabled,
    required this.onClear,
  });

  final Team team;
  final bool enabled;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceChip,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandGreen),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 20, color: AppColors.brandGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (team.sportLabel.isNotEmpty)
                  Text(
                    team.sportLabel,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (enabled)
            IconButton(
              onPressed: onClear,
              icon: Icon(Icons.close, size: 18, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}
