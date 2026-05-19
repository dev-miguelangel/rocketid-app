import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../teams/domain/team.dart';
import '../data/activities_api.dart';
import '../domain/activity_enums.dart';
import 'activity_form_fields.dart';
import 'location_picker.dart';
import 'opponent_team_picker.dart';

/// Asistente de creación de actividad en tres pasos.
class CreateActivityScreen extends ConsumerStatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  ConsumerState<CreateActivityScreen> createState() =>
      _CreateActivityScreenState();
}

class _CreateActivityScreenState extends ConsumerState<CreateActivityScreen> {
  static const _stepTitles = ['Actividad', 'Detalles', 'Inscripción'];

  int _step = 0;

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _locationInstructions = TextEditingController();
  final _maxParticipants = TextEditingController();
  final _playersPerSubteam = TextEditingController();
  final _reservesPerSubteam = TextEditingController();

  ActivityType _type = ActivityType.openCall;
  int? _sportId;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _requiresRegistration = false;
  DateTime? _registrationDeadline;
  LatLng? _location;
  String? _locationAddress;

  Team? _teamOne;
  Team? _teamTwo;
  Team? _team;
  TrainingMode _trainingMode = TrainingMode.classic;
  bool _allowExternals = false;
  OpenCallMode _openCallMode = OpenCallMode.open;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _locationInstructions.dispose();
    _maxParticipants.dispose();
    _playersPerSubteam.dispose();
    _reservesPerSubteam.dispose();
    super.dispose();
  }

  // --- Cambios de estado ----------------------------------------------------

  void _onTypeChanged(ActivityType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _sportId = null;
      _teamOne = null;
      _teamTwo = null;
      _team = null;
      _trainingMode = TrainingMode.classic;
      _allowExternals = false;
      _openCallMode = OpenCallMode.open;
      _maxParticipants.clear();
      _playersPerSubteam.clear();
      _reservesPerSubteam.clear();
      _error = null;
    });
  }

  // --- Fecha / hora ---------------------------------------------------------

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

  Future<void> _pickLocation() async {
    final picked = await pickActivityLocation(context, initial: _location);
    if (picked != null) {
      setState(() {
        _location = picked.point;
        _locationAddress = picked.address;
      });
    }
  }

  // --- Validación -----------------------------------------------------------

  String? _validateStep(int step) {
    switch (step) {
      case 0:
        if (_title.text.trim().isEmpty) return 'Ingresa un título';
        return null;
      case 1:
        final typeError = _validateTypeFields();
        if (typeError != null) return typeError;
        if (_startsAt == null) return 'Selecciona la fecha de inicio';
        if (_endsAt == null) return 'Selecciona la fecha de fin';
        if (!_endsAt!.isAfter(_startsAt!)) {
          return 'La fecha de fin debe ser posterior a la de inicio';
        }
        if (_startsAt!.isBefore(DateTime.now())) {
          return 'El inicio debe ser en el futuro';
        }
        if (_location == null) return 'Selecciona la ubicación';
        return null;
      case 2:
        if (_requiresRegistration) {
          if (_registrationDeadline == null) {
            return 'Selecciona la fecha límite de inscripción';
          }
          if (_registrationDeadline!
              .isAfter(_startsAt!.subtract(const Duration(hours: 1)))) {
            return 'La inscripción debe cerrar al menos 1 hora antes '
                'del inicio';
          }
        }
        return null;
      default:
        return null;
    }
  }

  String? _validateTypeFields() {
    switch (_type) {
      case ActivityType.openCall:
        if (_sportId == null) return 'Selecciona un deporte';
        if (_maxParticipants.text.trim().isNotEmpty) {
          final max = int.tryParse(_maxParticipants.text.trim());
          if (max == null || max <= 0) {
            return 'El cupo máximo debe ser un número válido';
          }
        }
      case ActivityType.training:
        if (_team == null) return 'Selecciona el equipo del entrenamiento';
        if (_trainingMode == TrainingMode.internalChallenge) {
          final players = int.tryParse(_playersPerSubteam.text.trim());
          final reserves = int.tryParse(_reservesPerSubteam.text.trim());
          if (players == null || players <= 0) {
            return 'Indica los jugadores por subequipo';
          }
          if (reserves == null || reserves < 0) {
            return 'Indica las reservas por subequipo';
          }
        }
      case ActivityType.challenge:
        if (_teamOne == null || _teamTwo == null) {
          return 'Selecciona los dos equipos del desafío';
        }
        if (_teamOne!.id == _teamTwo!.id) {
          return 'Los equipos del desafío deben ser distintos';
        }
        if (_teamOne!.sportId != _teamTwo!.sportId) {
          return 'Los equipos deben ser del mismo deporte';
        }
    }
    return null;
  }

  // --- Navegación entre pasos ----------------------------------------------

  void _next() {
    final error = _validateStep(_step);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_step < 2) {
      setState(() {
        _step++;
        _error = null;
      });
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      context.pop();
      return;
    }
    setState(() {
      _step--;
      _error = null;
    });
  }

  // --- Envío ----------------------------------------------------------------

  Map<String, dynamic> _buildBody() {
    final body = <String, dynamic>{
      'type': activityTypeToApi(_type),
      'title': _title.text.trim(),
      'sportId': _sportId,
      'startsAt': _startsAt!.toUtc().toIso8601String(),
      'endsAt': _endsAt!.toUtc().toIso8601String(),
      'requiresRegistration': _requiresRegistration,
      'latitude': _location!.latitude,
      'longitude': _location!.longitude,
    };
    if (_description.text.trim().isNotEmpty) {
      body['description'] = _description.text.trim();
    }
    if (_locationInstructions.text.trim().isNotEmpty) {
      body['locationInstructions'] = _locationInstructions.text.trim();
    }
    if (_requiresRegistration && _registrationDeadline != null) {
      body['registrationDeadline'] =
          _registrationDeadline!.toUtc().toIso8601String();
    }
    switch (_type) {
      case ActivityType.challenge:
        body['teamOneId'] = _teamOne!.id;
        body['teamTwoId'] = _teamTwo!.id;
      case ActivityType.training:
        body['teamId'] = _team!.id;
        body['trainingMode'] = trainingModeToApi(_trainingMode);
        if (_trainingMode == TrainingMode.internalChallenge) {
          body['playersPerSubteam'] =
              int.parse(_playersPerSubteam.text.trim());
          body['reservesPerSubteam'] =
              int.parse(_reservesPerSubteam.text.trim());
          body['allowExternals'] = _allowExternals;
        }
      case ActivityType.openCall:
        body['openCallMode'] = openCallModeToApi(_openCallMode);
        if (_maxParticipants.text.trim().isNotEmpty) {
          body['maxParticipants'] = int.parse(_maxParticipants.text.trim());
        }
    }
    return body;
  }

  Future<void> _submit() async {
    for (var s = 0; s <= 2; s++) {
      final error = _validateStep(s);
      if (error != null) {
        setState(() {
          _step = s;
          _error = error;
        });
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final created =
          await ref.read(activitiesApiProvider).create(_buildBody());
      ref.invalidate(agendaProvider);
      ref.invalidate(myActivitiesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Actividad "${created.displayTitle}" creada'),
            backgroundColor: AppColors.surfaceCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      context.pushReplacement('/agenda/${created.id}');
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
        _error = 'No pudimos crear la actividad';
      });
    }
  }

  // --- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppTopBar.inner(
        title: 'Nueva actividad',
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          _StepIndicator(step: _step, titles: _stepTitles),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                ..._stepContent(),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: AppColors.notificationDot,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  List<Widget> _stepContent() {
    switch (_step) {
      case 0:
        return _step1();
      case 1:
        return _step2();
      default:
        return _step3();
    }
  }

  // Paso 1: tipo, título, descripción.
  List<Widget> _step1() {
    return [
      const ActivityFormLabel('Tipo de actividad'),
      const SizedBox(height: 8),
      ActivityTypeSelector(
        value: _type,
        enabled: !_saving,
        onChanged: _onTypeChanged,
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
    ];
  }

  // Paso 2: deporte/equipos, modalidad, inicio, fin, lugar.
  List<Widget> _step2() {
    return [
      ..._typeSpecificFields(),
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
          final picked = await _pickDateTime(_endsAt ?? _startsAt);
          if (picked != null) setState(() => _endsAt = picked);
        },
      ),
      const SizedBox(height: 16),
      const ActivityFormLabel('Lugar'),
      const SizedBox(height: 8),
      ActivityLocationTile(
        value: _location,
        address: _locationAddress,
        onTap: _pickLocation,
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
    ];
  }

  List<Widget> _typeSpecificFields() {
    switch (_type) {
      case ActivityType.openCall:
        return [
          const ActivityFormLabel('Deporte'),
          const SizedBox(height: 8),
          SportPicker(
            value: _sportId,
            enabled: !_saving,
            onChanged: (v) => setState(() => _sportId = v),
          ),
          const SizedBox(height: 16),
          const ActivityFormLabel('Modalidad de convocatoria'),
          const SizedBox(height: 8),
          ActivityChoicePicker<OpenCallMode>(
            values: OpenCallMode.values,
            selected: _openCallMode,
            labelOf: openCallModeLabel,
            enabled: !_saving,
            onChanged: (v) => setState(() => _openCallMode = v),
          ),
          const SizedBox(height: 16),
          const ActivityFormLabel('Cupo máximo (opcional)'),
          const SizedBox(height: 8),
          ActivityTextField(
            controller: _maxParticipants,
            hint: 'Ej: 30',
            icon: Icons.groups,
            maxLength: 4,
            numeric: true,
            enabled: !_saving,
          ),
          const SizedBox(height: 16),
        ];
      case ActivityType.training:
        return [
          const ActivityFormLabel('Equipo'),
          const SizedBox(height: 8),
          MyTeamPicker(
            value: _team?.id,
            enabled: !_saving,
            hint: 'Selecciona el equipo',
            onChanged: (team) => setState(() {
              _team = team;
              _sportId = team?.sportId;
            }),
          ),
          const SizedBox(height: 16),
          const ActivityFormLabel('Deporte'),
          const SizedBox(height: 8),
          _SportReadonly(team: _team),
          const SizedBox(height: 16),
          const ActivityFormLabel('Modalidad'),
          const SizedBox(height: 8),
          ActivityChoicePicker<TrainingMode>(
            values: TrainingMode.values,
            selected: _trainingMode,
            labelOf: trainingModeLabel,
            enabled: !_saving,
            onChanged: (v) => setState(() => _trainingMode = v),
          ),
          if (_trainingMode == TrainingMode.internalChallenge) ...[
            const SizedBox(height: 16),
            const ActivityFormLabel('Jugadores por subequipo'),
            const SizedBox(height: 8),
            ActivityTextField(
              controller: _playersPerSubteam,
              hint: 'Ej: 5',
              icon: Icons.person,
              maxLength: 3,
              numeric: true,
              enabled: !_saving,
            ),
            const SizedBox(height: 16),
            const ActivityFormLabel('Reservas por subequipo'),
            const SizedBox(height: 8),
            ActivityTextField(
              controller: _reservesPerSubteam,
              hint: 'Ej: 2',
              icon: Icons.person_add_alt,
              maxLength: 3,
              numeric: true,
              enabled: !_saving,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.brandGreen,
              title: Text(
                'Permitir participantes externos',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              value: _allowExternals,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _allowExternals = v),
            ),
          ],
          const SizedBox(height: 16),
        ];
      case ActivityType.challenge:
        return [
          const ActivityFormLabel('Equipo 1 (tu equipo)'),
          const SizedBox(height: 8),
          MyTeamPicker(
            value: _teamOne?.id,
            enabled: !_saving,
            hint: 'Selecciona tu equipo',
            onChanged: (team) => setState(() {
              _teamOne = team;
              _sportId = team?.sportId;
              if (_teamTwo != null &&
                  team != null &&
                  _teamTwo!.sportId != team.sportId) {
                _teamTwo = null;
              }
            }),
          ),
          const SizedBox(height: 16),
          const ActivityFormLabel('Deporte'),
          const SizedBox(height: 8),
          _SportReadonly(team: _teamOne),
          const SizedBox(height: 16),
          const ActivityFormLabel('Equipo 2 (rival)'),
          const SizedBox(height: 8),
          OpponentTeamPicker(
            value: _teamTwo,
            sportId: _teamOne?.sportId,
            excludeTeamId: _teamOne?.id,
            enabled: !_saving,
            onChanged: (team) => setState(() => _teamTwo = team),
          ),
          const SizedBox(height: 16),
        ];
    }
  }

  // Paso 3: inscripción.
  List<Widget> _step3() {
    return [
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
        subtitle: Text(
          'Los participantes deben inscribirse antes de una fecha límite.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        value: _requiresRegistration,
        onChanged: _saving
            ? null
            : (v) => setState(() => _requiresRegistration = v),
      ),
      if (_requiresRegistration) ...[
        const SizedBox(height: 12),
        const ActivityFormLabel('Cierre de inscripción'),
        const SizedBox(height: 8),
        ActivityDateTimeTile(
          value: _registrationDeadline,
          hint: 'Al menos 1 hora antes del inicio',
          onTap: () async {
            final picked = await _pickDateTime(_registrationDeadline);
            if (picked != null) {
              setState(() => _registrationDeadline = picked);
            }
          },
        ),
      ],
    ];
  }

  Widget _bottomBar() {
    final isLast = _step == 2;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saving ? null : _back,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.borderChip),
                minimumSize: const Size.fromHeight(50),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: Text(_step == 0 ? 'Cancelar' : 'Atrás'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _saving ? null : _next,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.black,
                      ),
                    )
                  : Text(isLast ? 'Crear actividad' : 'Siguiente'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.titles});

  final int step;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < titles.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= step
                          ? AppColors.brandGreen
                          : AppColors.borderChip,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Paso ${step + 1} de ${titles.length} · ${titles[step]}',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SportReadonly extends StatelessWidget {
  const _SportReadonly({required this.team});

  final Team? team;

  @override
  Widget build(BuildContext context) {
    final label = team?.sportLabel ?? '';
    final String text;
    if (team == null) {
      text = 'Se asigna al elegir el equipo';
    } else if (label.isEmpty) {
      text = 'Deporte del equipo';
    } else {
      text = label;
    }
    return InputDecorator(
      decoration: activityFieldDecoration(icon: Icons.sports_outlined),
      child: Text(
        text,
        style: TextStyle(
          color: team == null ? AppColors.textFaint : AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
    );
  }
}
