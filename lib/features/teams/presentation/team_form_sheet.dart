import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../data/teams_api.dart';
import '../domain/sport.dart';
import '../domain/team.dart';
import 'team_icons.dart';
import 'team_logo.dart';

/// Hoja para crear un equipo o editar uno existente.
///
/// En modo edición ([existing] != null) solo se editan nombre, descripción e
/// imagen del logo (icono + color); deporte y género no se modifican porque la
/// API de `PATCH /teams/:id` documentada no los acepta.
class TeamFormSheet extends ConsumerStatefulWidget {
  const TeamFormSheet({super.key, this.existing});

  final Team? existing;

  bool get isEdit => existing != null;

  @override
  ConsumerState<TeamFormSheet> createState() => _TeamFormSheetState();
}

class _TeamFormSheetState extends ConsumerState<TeamFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  int? _sportId;
  late String _gender;
  late String _iconName;
  late String _colorHex;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _sportId = e?.sportId;
    _gender = e?.gender ?? 'mixed';
    _iconName = e?.icon ?? teamIconCatalog.first.name;
    _colorHex = e?.color ?? kTeamColors.first;
    if (!teamIconCatalog.any((t) => t.name == _iconName)) {
      _iconName = teamIconCatalog.first.name;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Ingresa un nombre');
      return;
    }
    if (!widget.isEdit && _sportId == null) {
      setState(() => _error = 'Selecciona un deporte');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final description = _description.text.trim();
    try {
      final api = ref.read(teamsApiProvider);
      final Team result;
      if (widget.isEdit) {
        result = await api.update(widget.existing!.id, <String, dynamic>{
          'name': name,
          'description': description,
          'icon': _iconName,
          'color': _colorHex,
        });
        ref.invalidate(teamDetailProvider(widget.existing!.id));
        ref.invalidate(myTeamsProvider);
      } else {
        result = await api.create(
          name: name,
          description: description.isEmpty ? null : description,
          icon: _iconName,
          color: _colorHex,
          gender: _gender,
          sportId: _sportId!,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = teamErrorMessage(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = widget.isEdit
            ? 'No pudimos actualizar el equipo'
            : 'No pudimos crear el equipo';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderChip,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isEdit ? 'Editar equipo' : 'Crear equipo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Center(
                    child: TeamLogo(
                      icon: _iconName,
                      colorHex: _colorHex,
                      size: 76,
                      radius: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label('Nombre'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _name,
                    hint: 'Ej: Los Tiburones',
                    icon: Icons.badge_outlined,
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  _label('Descripción (opcional)'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _description,
                    hint: 'Cuéntanos sobre el equipo',
                    icon: Icons.notes_outlined,
                    maxLength: 500,
                    maxLines: 3,
                  ),
                  if (!widget.isEdit) ...[
                    const SizedBox(height: 16),
                    _label('Deporte'),
                    const SizedBox(height: 8),
                    _SportPicker(
                      value: _sportId,
                      enabled: !_saving,
                      onChanged: (v) => setState(() => _sportId = v),
                    ),
                    const SizedBox(height: 16),
                    _label('Género'),
                    const SizedBox(height: 8),
                    _GenderPicker(
                      value: _gender,
                      enabled: !_saving,
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _label('Icono del logo'),
                  const SizedBox(height: 8),
                  _IconPicker(
                    selected: _iconName,
                    onChanged: (v) => setState(() => _iconName = v),
                  ),
                  const SizedBox(height: 16),
                  _label('Color de fondo'),
                  const SizedBox(height: 8),
                  _ColorPicker(
                    selected: _colorHex,
                    onChanged: (v) => setState(() => _colorHex = v),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: AppColors.notificationDot,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              widget.isEdit
                                  ? 'Guardar cambios'
                                  : 'Crear equipo',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required int maxLength,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: !_saving,
      maxLines: maxLines,
      maxLength: maxLength,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      cursorColor: AppColors.brandGreen,
      inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
      decoration: InputDecoration(
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SportPicker extends ConsumerWidget {
  const _SportPicker({
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
          decoration: _decoration(Icons.sports_outlined),
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
        decoration: _decoration(Icons.sports_outlined),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.brandGreen,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Cargando deportes…',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
      error: (err, _) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ref.invalidate(sportsListProvider),
        child: InputDecorator(
          decoration: _decoration(Icons.error_outline),
          child: Text(
            'No pudimos cargar deportes. Toca para reintentar.',
            style: TextStyle(color: AppColors.notificationDot, fontSize: 13),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(IconData icon) => InputDecoration(
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

class _GenderPicker extends StatelessWidget {
  const _GenderPicker({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final g in kTeamGenders)
          ChoiceChip(
            label: Text(genderLabel(g)),
            selected: value == g,
            onSelected: enabled ? (_) => onChanged(g) : null,
            showCheckmark: false,
            backgroundColor: AppColors.surfaceChip,
            selectedColor: AppColors.brandGreen,
            side: BorderSide(
              color: value == g ? AppColors.brandGreen : AppColors.borderChip,
            ),
            labelStyle: TextStyle(
              color: value == g ? Colors.black : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: teamIconCatalog.length,
        itemBuilder: (context, i) {
          final item = teamIconCatalog[i];
          final isSelected = item.name == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(item.name),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceChip,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.brandGreen
                      : AppColors.borderChip,
                  width: isSelected ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                item.icon,
                color:
                    isSelected ? AppColors.brandGreen : AppColors.textSecondary,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final hex in kTeamColors)
          GestureDetector(
            onTap: () => onChanged(hex),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: parseTeamColor(hex),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected.toUpperCase() == hex.toUpperCase()
                      ? AppColors.textPrimary
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: selected.toUpperCase() == hex.toUpperCase()
                  ? Icon(Icons.check,
                      size: 18, color: onTeamColor(parseTeamColor(hex)))
                  : null,
            ),
          ),
      ],
    );
  }
}
