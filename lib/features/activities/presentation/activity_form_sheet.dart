import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../data/activities_api.dart';
import '../domain/activity.dart';
import 'activity_form_fields.dart';
import 'location_picker.dart';

/// Abre el formulario de **edición** de una actividad. Devuelve la actividad
/// actualizada, o `null` si se cancela.
///
/// La creación usa el asistente por pasos (`CreateActivityScreen`), no esta
/// hoja: ver [createActivityFlow].
Future<Activity?> openActivityFormSheet(
  BuildContext context, {
  required Activity existing,
}) {
  return showModalBottomSheet<Activity>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ActivityFormSheet(existing: existing),
  );
}

/// Lanza el asistente de creación de actividad (pantalla por pasos).
void createActivityFlow(BuildContext context, WidgetRef ref) {
  context.push('/agenda/crear');
}

/// Hoja modal para **editar** una actividad existente.
///
/// Solo se modifican los campos comunes; el `type` es inmutable y los campos
/// específicos del tipo no se editan (la API de `PATCH` no los acepta).
class ActivityFormSheet extends ConsumerStatefulWidget {
  const ActivityFormSheet({super.key, required this.existing});

  final Activity existing;

  @override
  ConsumerState<ActivityFormSheet> createState() => _ActivityFormSheetState();
}

class _ActivityFormSheetState extends ConsumerState<ActivityFormSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _locationInstructions = TextEditingController();

  late int? _sportId;
  late DateTime _startsAt;
  late DateTime _endsAt;
  late bool _requiresRegistration;
  DateTime? _registrationDeadline;
  late LatLng _location;
  String? _locationAddress;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title.text = e.title;
    _description.text = e.description ?? '';
    _locationInstructions.text = e.locationInstructions ?? '';
    _sportId = e.sportId;
    _startsAt = e.startsAt.toLocal();
    _endsAt = e.endsAt.toLocal();
    _requiresRegistration = e.requiresRegistration;
    _registrationDeadline = e.registrationDeadline?.toLocal();
    _location = LatLng(e.latitude, e.longitude);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _locationInstructions.dispose();
    super.dispose();
  }

  // --- Selección de fecha/hora ----------------------------------------------

  Widget _darkPicker(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.dark(
          primary: AppColors.brandGreen,
          onPrimary: Colors.black,
          surface: AppColors.surfaceCard,
        ),
      ),
      child: child!,
    );
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final base = initial ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(now) ? now : base,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      builder: _darkPicker,
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      builder: _darkPicker,
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // --- Envío ----------------------------------------------------------------

  String? _validate() {
    if (_title.text.trim().isEmpty) return 'Ingresa un título';
    if (_sportId == null) return 'Selecciona un deporte';
    if (!_endsAt.isAfter(_startsAt)) {
      return 'La fecha de fin debe ser posterior a la de inicio';
    }
    if (_requiresRegistration) {
      if (_registrationDeadline == null) {
        return 'Selecciona la fecha límite de inscripción';
      }
      if (_registrationDeadline!
          .isAfter(_startsAt.subtract(const Duration(hours: 1)))) {
        return 'La inscripción debe cerrar al menos 1 hora antes del inicio';
      }
    }
    return null;
  }

  /// Campos comunes editables (`PATCH /activities/:id`).
  Map<String, dynamic> _buildPatch() {
    final patch = <String, dynamic>{
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'sportId': _sportId,
      'startsAt': _startsAt.toUtc().toIso8601String(),
      'endsAt': _endsAt.toUtc().toIso8601String(),
      'requiresRegistration': _requiresRegistration,
      'latitude': _location.latitude,
      'longitude': _location.longitude,
      'locationInstructions': _locationInstructions.text.trim(),
    };
    if (_requiresRegistration && _registrationDeadline != null) {
      patch['registrationDeadline'] =
          _registrationDeadline!.toUtc().toIso8601String();
    }
    return patch;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final activity = await ref
          .read(activitiesApiProvider)
          .update(widget.existing.id, _buildPatch());
      ref.invalidate(activityDetailProvider(widget.existing.id));
      ref.invalidate(agendaProvider);
      ref.invalidate(myActivitiesProvider);
      if (!mounted) return;
      Navigator.of(context).pop(activity);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = activityErrorMessage(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No pudimos actualizar la actividad';
      });
    }
  }

  // --- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderChip,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Editar actividad',
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
                  const ActivityFormLabel('Tipo de actividad'),
                  const SizedBox(height: 8),
                  ActivityTypeSelector(
                    value: widget.existing.type,
                    enabled: false,
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 16),
                  const ActivityFormLabel('Título'),
                  const SizedBox(height: 8),
                  ActivityTextField(
                    controller: _title,
                    hint: 'Ej: Caminata al cerro',
                    icon: Icons.title,
                    maxLength: 150,
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 16),
                  const ActivityFormLabel('Descripción (opcional)'),
                  const SizedBox(height: 8),
                  ActivityTextField(
                    controller: _description,
                    hint: 'Detalles de la actividad',
                    icon: Icons.notes_outlined,
                    maxLength: 500,
                    maxLines: 3,
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 16),
                  const ActivityFormLabel('Deporte'),
                  const SizedBox(height: 8),
                  SportPicker(
                    value: _sportId,
                    enabled: !_saving,
                    onChanged: (v) => setState(() => _sportId = v),
                  ),
                  const SizedBox(height: 16),
                  const ActivityFormLabel('Inicio'),
                  const SizedBox(height: 8),
                  ActivityDateTimeTile(
                    value: _startsAt,
                    hint: 'Selecciona fecha y hora',
                    onTap: () async {
                      final picked = await _pickDateTime(_startsAt);
                      if (picked != null) setState(() => _startsAt = picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  const ActivityFormLabel('Fin'),
                  const SizedBox(height: 8),
                  ActivityDateTimeTile(
                    value: _endsAt,
                    hint: 'Selecciona fecha y hora',
                    onTap: () async {
                      final picked = await _pickDateTime(_endsAt);
                      if (picked != null) setState(() => _endsAt = picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.brandGreen,
                    title: Text(
                      'Requiere inscripción',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: _requiresRegistration,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _requiresRegistration = v),
                  ),
                  if (_requiresRegistration) ...[
                    const SizedBox(height: 8),
                    const ActivityFormLabel('Cierre de inscripción'),
                    const SizedBox(height: 8),
                    ActivityDateTimeTile(
                      value: _registrationDeadline,
                      hint: 'Al menos 1 hora antes del inicio',
                      onTap: () async {
                        final picked =
                            await _pickDateTime(_registrationDeadline);
                        if (picked != null) {
                          setState(() => _registrationDeadline = picked);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  const ActivityFormLabel('Lugar'),
                  const SizedBox(height: 8),
                  ActivityLocationTile(
                    value: _location,
                    address: _locationAddress,
                    onTap: () async {
                      final picked = await pickActivityLocation(
                        context,
                        initial: _location,
                      );
                      if (picked != null) {
                        setState(() {
                          _location = picked.point;
                          _locationAddress = picked.address;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ActivityTextField(
                    controller: _locationInstructions,
                    hint: 'Instrucciones del lugar (opcional)',
                    icon: Icons.place_outlined,
                    maxLength: 300,
                    maxLines: 2,
                    enabled: !_saving,
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
                          : const Text(
                              'Guardar cambios',
                              style: TextStyle(
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
}
