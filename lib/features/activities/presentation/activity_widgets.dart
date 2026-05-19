import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../teams/domain/sport.dart';
import '../../teams/presentation/team_icons.dart';
import '../../teams/presentation/team_logo.dart';
import '../domain/activity_enums.dart';

// ---------------------------------------------------------------------------
// Formato de fechas (español, sin dependencia de locale data)
// ---------------------------------------------------------------------------

const List<String> _monthsShort = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

const List<String> _monthsFull = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

const List<String> _weekdaysFull = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// Hora local, formato `HH:mm`.
String activityTimeLabel(DateTime dt) {
  final local = dt.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// Fecha corta local, p. ej. `1 jun`.
String activityShortDate(DateTime dt) {
  final local = dt.toLocal();
  return '${local.day} ${_monthsShort[local.month - 1]}';
}

/// Encabezado de día para la agenda: `Hoy`, `Mañana` o `Lunes 1 de junio`.
String activityDayHeaderLabel(DateTime dt) {
  final local = dt.toLocal();
  final now = DateTime.now();
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  return '${_weekdaysFull[local.weekday - 1]} ${local.day} de '
      '${_monthsFull[local.month - 1]}';
}

/// Rango horario `HH:mm – HH:mm`.
String activityTimeRange(DateTime start, DateTime end) =>
    '${activityTimeLabel(start)} – ${activityTimeLabel(end)}';

// ---------------------------------------------------------------------------
// Chips de tipo y estado
// ---------------------------------------------------------------------------

class ActivityTypeChip extends StatelessWidget {
  const ActivityTypeChip(this.type, {super.key});

  final ActivityType type;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      label: activityTypeLabel(type),
      fg: AppColors.brandGreen,
      bg: AppColors.brandGreen.withValues(alpha: 0.12),
    );
  }
}

class ActivityStatusChip extends StatelessWidget {
  const ActivityStatusChip(this.status, {super.key});

  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    switch (status) {
      case ActivityStatus.scheduled:
        fg = AppColors.textMuted;
      case ActivityStatus.inProgress:
        fg = AppColors.brandGreen;
      case ActivityStatus.completed:
        fg = AppColors.textFaint;
      case ActivityStatus.cancelled:
        fg = AppColors.notificationDot;
    }
    return _Pill(
      label: activityStatusLabel(status),
      fg: fg,
      bg: fg.withValues(alpha: 0.12),
    );
  }
}

/// Chip de deporte: icono + etiqueta, coloreado con `sport.color`.
class SportChip extends StatelessWidget {
  const SportChip(this.sport, {super.key});

  final Sport sport;

  @override
  Widget build(BuildContext context) {
    final color = parseTeamColor(sport.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(resolveSportIcon(sport.icon), color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            sport.displayLabel,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.fg, required this.bg});

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estados de carga / vacío / error
// ---------------------------------------------------------------------------

class ActivityLoadingState extends StatelessWidget {
  const ActivityLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.brandGreen,
          ),
        ),
      ),
    );
  }
}

class ActivityEmptyState extends StatelessWidget {
  const ActivityEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 44),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityErrorState extends StatelessWidget {
  const ActivityErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off,
            color: AppColors.textMuted,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No pudimos cargar la información',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
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
      ),
    );
  }
}
