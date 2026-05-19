import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/theme/app_colors.dart';
import '../auth/application/session_state.dart';
import '../profile/profile_screen.dart' show bloodTypeOptions;
import 'widgets/onboarding_scaffold.dart';

class OnboardingMedicalScreen extends ConsumerStatefulWidget {
  const OnboardingMedicalScreen({super.key});

  @override
  ConsumerState<OnboardingMedicalScreen> createState() =>
      _OnboardingMedicalScreenState();
}

class _OnboardingMedicalScreenState
    extends ConsumerState<OnboardingMedicalScreen> {
  final _allergiesCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  String? _bloodType;
  bool _busy = false;
  String? _profileId;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionControllerProvider);
    if (session is SessionAuthenticated) {
      final p = session.user.profile;
      _profileId = p?.id;
      _bloodType = p?.bloodType;
      _allergiesCtrl.text = (p?.allergies ?? const []).join(', ');
      _conditionsCtrl.text = p?.conditions ?? '';
      _medicationsCtrl.text = (p?.medications ?? const []).join(', ');
    }
  }

  @override
  void dispose() {
    _allergiesCtrl.dispose();
    _conditionsCtrl.dispose();
    _medicationsCtrl.dispose();
    super.dispose();
  }

  List<String> _splitCsv(String raw) => raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);

  Map<String, dynamic> _buildPayload() {
    final p = <String, dynamic>{};
    if (_bloodType != null && _bloodType!.isNotEmpty) {
      p['bloodType'] = _bloodType;
    }
    final allergies = _splitCsv(_allergiesCtrl.text);
    if (allergies.isNotEmpty) p['allergies'] = allergies;
    final conditions = _conditionsCtrl.text.trim();
    if (conditions.isNotEmpty) p['conditions'] = conditions;
    final medications = _splitCsv(_medicationsCtrl.text);
    if (medications.isNotEmpty) p['medications'] = medications;
    return p;
  }

  Future<void> _submit({required bool skip}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!skip) {
        final payload = _buildPayload();
        if (_profileId != null && payload.isNotEmpty) {
          await ref.read(profileApiProvider).update(_profileId!, payload);
        }
      }
      if (!mounted) return;
      context.go('/onboarding/emergency');
    } catch (_) {
      _toast('No se pudo guardar la información');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 3,
      totalSteps: 4,
      title: 'Información médica',
      subtitle:
          'Opcional. Tus contactos podrán verla en caso de emergencia. Podrás completarla después desde tu perfil.',
      busy: _busy,
      primaryLabel: 'Continuar',
      onPrimary: () => _submit(skip: false),
      secondaryLabel: 'Omitir por ahora',
      onSecondary: () => _submit(skip: true),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: bloodTypeOptions.containsKey(_bloodType)
                ? _bloodType
                : null,
            isExpanded: true,
            dropdownColor: AppColors.surfaceCard,
            iconEnabledColor: AppColors.textMuted,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: onboardingFieldDecoration(
              label: 'Tipo de sangre',
              icon: Icons.bloodtype_outlined,
            ),
            items: [
              for (final entry in bloodTypeOptions.entries)
                DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
            ],
            onChanged: (v) => setState(() => _bloodType = v),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _allergiesCtrl,
            style: TextStyle(color: AppColors.textPrimary),
            cursorColor: AppColors.brandGreen,
            decoration: onboardingFieldDecoration(
              label: 'Alergias',
              icon: Icons.warning_amber_outlined,
              hint: 'Separadas por coma',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _conditionsCtrl,
            maxLines: 3,
            style: TextStyle(color: AppColors.textPrimary),
            cursorColor: AppColors.brandGreen,
            decoration: onboardingFieldDecoration(
              label: 'Condiciones',
              icon: Icons.healing_outlined,
              hint: 'Asma, diabetes, etc.',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _medicationsCtrl,
            style: TextStyle(color: AppColors.textPrimary),
            cursorColor: AppColors.brandGreen,
            decoration: onboardingFieldDecoration(
              label: 'Medicamentos',
              icon: Icons.medication_outlined,
              hint: 'Separados por coma',
            ),
          ),
        ],
      ),
    );
  }
}
