import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../teams/domain/sport.dart';
import '../../teams/domain/team.dart';
import '../domain/activity_enums.dart';
import 'activity_widgets.dart';

/// Decoración compartida por los campos del formulario de actividad.
InputDecoration activityFieldDecoration({
  String? hint,
  required IconData icon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.textFaint, fontSize: 14),
    counterText: '',
    prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
    filled: true,
    fillColor: AppColors.surfaceChip,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.borderChip),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.borderChip),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.brandGreen),
    ),
  );
}

/// Etiqueta de un campo del formulario.
class ActivityFormLabel extends StatelessWidget {
  const ActivityFormLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Campo de texto del formulario de actividad.
class ActivityTextField extends StatelessWidget {
  const ActivityTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.maxLength,
    this.maxLines = 1,
    this.numeric = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLength;
  final int maxLines;
  final bool numeric;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: [
        LengthLimitingTextInputFormatter(maxLength),
        if (numeric) FilteringTextInputFormatter.digitsOnly,
      ],
      style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      cursorColor: AppColors.brandGreen,
      decoration: activityFieldDecoration(hint: hint, icon: icon),
    );
  }
}

/// Selector del tipo de actividad.
class ActivityTypeSelector extends StatelessWidget {
  const ActivityTypeSelector({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final ActivityType value;
  final bool enabled;
  final ValueChanged<ActivityType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final t in ActivityType.values)
          ChoiceChip(
            label: Text(activityTypeLabel(t)),
            selected: value == t,
            onSelected: enabled ? (_) => onChanged(t) : null,
            showCheckmark: false,
            backgroundColor: AppColors.surfaceChip,
            selectedColor: AppColors.brandGreen,
            side: BorderSide(
              color: value == t ? AppColors.brandGreen : AppColors.borderChip,
            ),
            labelStyle: TextStyle(
              color: value == t ? Colors.black : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

/// Selector de una opción dentro de un conjunto pequeño de valores.
class ActivityChoicePicker<T> extends StatelessWidget {
  const ActivityChoicePicker({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.enabled,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final bool enabled;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final v in values)
          ChoiceChip(
            label: Text(labelOf(v)),
            selected: selected == v,
            onSelected: enabled ? (_) => onChanged(v) : null,
            showCheckmark: false,
            backgroundColor: AppColors.surfaceChip,
            selectedColor: AppColors.brandGreen,
            side: BorderSide(
              color: selected == v
                  ? AppColors.brandGreen
                  : AppColors.borderChip,
            ),
            labelStyle: TextStyle(
              color: selected == v ? Colors.black : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

/// Tile que abre un selector de fecha y hora.
class ActivityDateTimeTile extends StatelessWidget {
  const ActivityDateTimeTile({
    super.key,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final DateTime? value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final text = hasValue
        ? '${activityShortDate(value!)} · ${activityTimeLabel(value!)}'
        : hint;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: activityFieldDecoration(icon: Icons.event),
        child: Text(
          text,
          style: TextStyle(
            color: hasValue ? AppColors.textPrimary : AppColors.textFaint,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Tile que abre el selector de ubicación. Muestra la dirección elegida si
/// existe; si no, las coordenadas.
class ActivityLocationTile extends StatelessWidget {
  const ActivityLocationTile({
    super.key,
    required this.value,
    this.address,
    required this.onTap,
  });

  final LatLng? value;
  final String? address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final String text;
    if (address != null && address!.trim().isNotEmpty) {
      text = address!.trim();
    } else if (hasValue) {
      text = '${value!.latitude.toStringAsFixed(5)}, '
          '${value!.longitude.toStringAsFixed(5)}';
    } else {
      text = 'Escribe una dirección o elige en el mapa';
    }
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: activityFieldDecoration(icon: Icons.place_outlined),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: hasValue ? AppColors.textPrimary : AppColors.textFaint,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Selector de deporte que consume `sportsListProvider`.
class SportPicker extends ConsumerWidget {
  const SportPicker({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final int? value;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportsAsync = ref.watch(sportsListProvider);
    return sportsAsync.when(
      data: (sports) {
        final validValue = sports.any((s) => s.id == value) ? value : null;
        return DropdownButtonFormField<int>(
          initialValue: validValue,
          isExpanded: true,
          dropdownColor: AppColors.surfaceCard,
          iconEnabledColor: AppColors.textMuted,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: activityFieldDecoration(icon: Icons.sports_outlined),
          hint: Text(
            'Selecciona un deporte',
            style: TextStyle(color: AppColors.textFaint, fontSize: 14),
          ),
          items: [
            for (final Sport s in sports)
              DropdownMenuItem<int>(value: s.id, child: Text(s.displayLabel)),
          ],
          onChanged: enabled ? onChanged : null,
        );
      },
      loading: () => InputDecorator(
        decoration: activityFieldDecoration(icon: Icons.sports_outlined),
        child: Text(
          'Cargando deportes…',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
      ),
      error: (_, _) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ref.invalidate(sportsListProvider),
        child: InputDecorator(
          decoration: activityFieldDecoration(icon: Icons.error_outline),
          child: Text(
            'No pudimos cargar deportes. Toca para reintentar.',
            style: TextStyle(color: AppColors.notificationDot, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

/// Selector de un equipo propio (`myTeamsProvider`). Entrega el [Team]
/// completo en [onChanged] para poder leer su deporte.
class MyTeamPicker extends ConsumerWidget {
  const MyTeamPicker({
    super.key,
    required this.value,
    required this.enabled,
    required this.hint,
    required this.onChanged,
  });

  final String? value;
  final bool enabled;
  final String hint;
  final ValueChanged<Team?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(myTeamsProvider);
    return teamsAsync.when(
      data: (teams) {
        if (teams.isEmpty) {
          return InputDecorator(
            decoration: activityFieldDecoration(icon: Icons.groups_outlined),
            child: Text(
              'No tienes equipos disponibles',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          );
        }
        final validValue = teams.any((t) => t.id == value) ? value : null;
        return DropdownButtonFormField<String>(
          initialValue: validValue,
          isExpanded: true,
          dropdownColor: AppColors.surfaceCard,
          iconEnabledColor: AppColors.textMuted,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: activityFieldDecoration(icon: Icons.groups_outlined),
          hint: Text(
            hint,
            style: TextStyle(color: AppColors.textFaint, fontSize: 14),
          ),
          items: [
            for (final Team t in teams)
              DropdownMenuItem<String>(value: t.id, child: Text(t.name)),
          ],
          onChanged: enabled
              ? (id) {
                  if (id == null) {
                    onChanged(null);
                    return;
                  }
                  onChanged(teams.firstWhere((t) => t.id == id));
                }
              : null,
        );
      },
      loading: () => InputDecorator(
        decoration: activityFieldDecoration(icon: Icons.groups_outlined),
        child: Text(
          'Cargando equipos…',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
      ),
      error: (_, _) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ref.invalidate(myTeamsProvider),
        child: InputDecorator(
          decoration: activityFieldDecoration(icon: Icons.error_outline),
          child: Text(
            'No pudimos cargar equipos. Toca para reintentar.',
            style: TextStyle(color: AppColors.notificationDot, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
