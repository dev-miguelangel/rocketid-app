import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/theme/app_colors.dart';
import '../auth/application/session_state.dart';
import '../profile/profile_screen.dart' show genderOptions;
import 'data/cities_chile.dart';
import 'widgets/onboarding_scaffold.dart';

class OnboardingPersonalScreen extends ConsumerStatefulWidget {
  const OnboardingPersonalScreen({super.key});

  @override
  ConsumerState<OnboardingPersonalScreen> createState() =>
      _OnboardingPersonalScreenState();
}

class _OnboardingPersonalScreenState
    extends ConsumerState<OnboardingPersonalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  String? _birthDate;
  String? _gender;
  String? _city;
  bool _busy = false;
  String? _profileId;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionControllerProvider);
    if (session is SessionAuthenticated) {
      final p = session.user.profile;
      _profileId = p?.id;
      _birthDate = p?.birthDate;
      _gender = p?.gender;
      _city = p?.city;
      _phoneCtrl.text = p?.phone ?? '';
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _isComplete =>
      _birthDate != null &&
      _birthDate!.isNotEmpty &&
      _gender != null &&
      _city != null &&
      _phoneCtrl.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_isComplete || _profileId == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(profileApiProvider).update(_profileId!, {
        'birthDate': _birthDate,
        'gender': _gender,
        'city': _city,
        'phone': _phoneCtrl.text.trim(),
      });
      if (!mounted) return;
      context.go('/onboarding/medical');
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

  Future<void> _pickBirthDate() async {
    final parsed = _birthDate != null ? DateTime.tryParse(_birthDate!) : null;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.brandGreen,
            onPrimary: Colors.black,
            surface: AppColors.surfaceCard,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.surfaceCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _birthDate =
            '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 2,
      totalSteps: 4,
      title: 'Información personal',
      subtitle:
          'Esta información nos ayuda a personalizar tu perfil. Todos los campos son obligatorios.',
      busy: _busy,
      primaryEnabled: _isComplete,
      primaryLabel: 'Continuar',
      onPrimary: _submit,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: () => setState(() {}),
        child: Column(
          children: [
            _BirthDateTile(value: _birthDate, onTap: _pickBirthDate),
            const SizedBox(height: 14),
            _GenderDropdown(
              value: _gender,
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 14),
            _CityDropdown(
              value: _city,
              onChanged: (v) => setState(() => _city = v),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                LengthLimitingTextInputFormatter(20),
              ],
              style: TextStyle(color: AppColors.textPrimary),
              cursorColor: AppColors.brandGreen,
              decoration: onboardingFieldDecoration(
                label: 'Teléfono',
                icon: Icons.phone_outlined,
                hint: '+56 9 1234 5678',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Escribe tu teléfono'
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BirthDateTile extends StatelessWidget {
  const _BirthDateTile({required this.value, required this.onTap});

  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: IgnorePointer(
        child: TextFormField(
          key: ValueKey(value),
          initialValue: hasValue ? value : '',
          enabled: false,
          style: TextStyle(
            color: hasValue ? AppColors.textPrimary : AppColors.textFaint,
          ),
          decoration:
              onboardingFieldDecoration(
                label: 'Fecha de nacimiento',
                icon: Icons.cake_outlined,
                hint: 'YYYY-MM-DD',
              ).copyWith(
                suffixIcon: Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
          validator: (_) => hasValue ? null : 'Selecciona tu fecha',
        ),
      ),
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  const _GenderDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final validValue = genderOptions.containsKey(value) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: validValue,
      isExpanded: true,
      dropdownColor: AppColors.surfaceCard,
      iconEnabledColor: AppColors.textMuted,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: onboardingFieldDecoration(
        label: 'Género',
        icon: Icons.wc_outlined,
      ),
      items: [
        for (final entry in genderOptions.entries)
          DropdownMenuItem<String>(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: onChanged,
      validator: (v) => v == null ? 'Selecciona un género' : null,
    );
  }
}

class _CityDropdown extends StatelessWidget {
  const _CityDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final validValue = kChileCitiesFlat.contains(value) ? value : null;
    final items = <DropdownMenuItem<String>>[];
    for (final entry in kChileCitiesByZone.entries) {
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          value: '__zone_${entry.key}',
          child: Text(
            entry.key.toUpperCase(),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
      );
      for (final city in entry.value) {
        items.add(
          DropdownMenuItem<String>(
            value: city,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(city),
            ),
          ),
        );
      }
    }
    return DropdownButtonFormField<String>(
      initialValue: validValue,
      isExpanded: true,
      menuMaxHeight: 360,
      dropdownColor: AppColors.surfaceCard,
      iconEnabledColor: AppColors.textMuted,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: onboardingFieldDecoration(
        label: 'Ciudad',
        icon: Icons.location_city_outlined,
      ),
      items: items,
      onChanged: onChanged,
      validator: (v) => v == null ? 'Selecciona una ciudad' : null,
    );
  }
}
