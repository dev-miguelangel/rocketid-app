import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../shared/theme/app_colors.dart';
import '../auth/application/session_state.dart';
import 'widgets/onboarding_scaffold.dart';

const _kRelationshipOptions = <String>[
  'padre',
  'madre',
  'hijo',
  'hija',
  'hermano',
  'hermana',
  'abuelo',
  'abuela',
  'nieto',
  'nieta',
  'tío',
  'tía',
  'primo',
  'prima',
  'amigo',
  'amiga',
  'otro',
];

class OnboardingEmergencyScreen extends ConsumerStatefulWidget {
  const OnboardingEmergencyScreen({super.key});

  @override
  ConsumerState<OnboardingEmergencyScreen> createState() =>
      _OnboardingEmergencyScreenState();
}

class _OnboardingEmergencyScreenState
    extends ConsumerState<OnboardingEmergencyScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _relationship;
  bool _busy = false;
  String? _profileId;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionControllerProvider);
    if (session is SessionAuthenticated) {
      final p = session.user.profile;
      _profileId = p?.id;
      _nameCtrl.text = p?.emergencyContactName ?? '';
      _phoneCtrl.text = p?.emergencyContactPhone ?? '';
      _relationship = p?.emergencyContactRelationship;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    final p = <String, dynamic>{};
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isNotEmpty) p['emergencyContactName'] = name;
    if (phone.isNotEmpty) p['emergencyContactPhone'] = phone;
    if (_relationship != null && _relationship!.isNotEmpty) {
      p['emergencyContactRelationship'] = _relationship;
    }
    return p;
  }

  Future<void> _submit({required bool skip}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!skip) {
        final payload = _buildPayload();
        if (payload.isNotEmpty && _profileId != null) {
          await ref.read(profileApiProvider).update(_profileId!, payload);
        }
      }
      await ref.read(sessionControllerProvider.notifier).setOnboardingStep(5);
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
      step: 4,
      totalSteps: 4,
      title: 'Contacto de emergencia',
      subtitle:
          'Opcional. Tus contactos podrán llamarlo o escribirle desde tu perfil en caso de emergencia.',
      busy: _busy,
      primaryLabel: 'Continuar',
      onPrimary: () => _submit(skip: false),
      secondaryLabel: 'Omitir por ahora',
      onSecondary: () => _submit(skip: true),
      child: Column(
        children: [
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: AppColors.textPrimary),
            cursorColor: AppColors.brandGreen,
            decoration: onboardingFieldDecoration(
              label: 'Nombre',
              icon: Icons.person_outline,
              hint: 'Nombre completo',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
              LengthLimitingTextInputFormatter(20),
            ],
            style: const TextStyle(color: AppColors.textPrimary),
            cursorColor: AppColors.brandGreen,
            decoration: onboardingFieldDecoration(
              label: 'Teléfono',
              icon: Icons.phone_outlined,
              hint: '+56 9 1234 5678',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _kRelationshipOptions.contains(_relationship)
                ? _relationship
                : null,
            isExpanded: true,
            menuMaxHeight: 360,
            dropdownColor: AppColors.surfaceCard,
            iconEnabledColor: AppColors.textMuted,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: onboardingFieldDecoration(
              label: 'Relación',
              icon: Icons.favorite_border,
            ),
            items: [
              for (final r in _kRelationshipOptions)
                DropdownMenuItem<String>(
                  value: r,
                  child: Text(r[0].toUpperCase() + r.substring(1)),
                ),
            ],
            onChanged: (v) => setState(() => _relationship = v),
          ),
        ],
      ),
    );
  }
}
