import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_nav_handler.dart';
import '../../shared/widgets/app_top_bar.dart';
import 'domain/activity.dart';
import 'domain/activity_enums.dart';
import 'domain/activity_filter.dart';
import 'presentation/activity_form_sheet.dart';
import 'presentation/activity_list_tile.dart';
import 'presentation/activity_widgets.dart';

/// Agenda de actividades: lista las actividades del backend agrupadas por día,
/// con filtro por tipo.
class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  ActivityType? _typeFilter;

  ActivityFilter get _filter => ActivityFilter(type: _typeFilter);

  @override
  Widget build(BuildContext context) {
    final agendaAsync = ref.watch(agendaProvider(_filter));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppTopBar.inner(title: 'Agenda'),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (i) => handleNavTap(
          context,
          i,
          currentIndex: 1,
          onCreateActivity: () => createActivityFlow(context, ref),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => createActivityFlow(context, ref),
        backgroundColor: AppColors.brandGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Crear actividad',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          _TypeFilterBar(
            selected: _typeFilter,
            onChanged: (t) => setState(() => _typeFilter = t),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandGreen,
              backgroundColor: AppColors.surfaceCard,
              onRefresh: () async {
                ref.invalidate(agendaProvider(_filter));
                await ref.read(agendaProvider(_filter).future);
              },
              child: agendaAsync.when(
                data: (list) => _AgendaList(activities: list),
                loading: () => ListView(
                  children: const [ActivityLoadingState()],
                ),
                error: (_, _) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ActivityErrorState(
                      onRetry: () => ref.invalidate(agendaProvider(_filter)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar({required this.selected, required this.onChanged});

  final ActivityType? selected;
  final ValueChanged<ActivityType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, ActivityType?)>[
      ('Todas', null),
      ('Convocatorias', ActivityType.openCall),
      ('Desafíos', ActivityType.challenge),
      ('Entrenamientos', ActivityType.training),
    ];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, type) = entries[i];
          final isActive = selected == type;
          return GestureDetector(
            onTap: () => onChanged(type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.brandGreen.withValues(alpha: 0.14)
                    : AppColors.surfaceChip,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? AppColors.brandGreen
                      : AppColors.borderChip,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? AppColors.brandGreen
                      : AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AgendaList extends StatelessWidget {
  const _AgendaList({required this.activities});

  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ActivityEmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'Sin actividades',
            subtitle:
                'Aún no hay actividades en la agenda. Crea una con el botón +.',
          ),
        ],
      );
    }

    final sorted = [...activities]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    // Construye una lista plana con encabezados de día.
    final items = <Widget>[];
    DateTime? currentDay;
    for (final activity in sorted) {
      final local = activity.startsAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (currentDay != day) {
        currentDay = day;
        items.add(_DayHeader(label: activityDayHeaderLabel(activity.startsAt)));
      }
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ActivityListTile(activity: activity),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: items,
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
