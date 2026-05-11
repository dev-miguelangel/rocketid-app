import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../auth/domain/user.dart';
import 'profile_screen.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, required this.user});

  final User user;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _city;
  late final TextEditingController _phone;
  late final TextEditingController _alias;
  late final TextEditingController _allergies;
  late final TextEditingController _conditions;
  late final TextEditingController _medications;
  late final TextEditingController _emergencyName;
  late final TextEditingController _emergencyPhone;
  late final TextEditingController _emergencyRel;

  String? _birthDate;
  String? _gender;
  String? _bloodType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.user.profile;
    _city = TextEditingController(text: p?.city ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
    _alias = TextEditingController(text: p?.alias ?? '');
    _allergies =
        TextEditingController(text: (p?.allergies ?? const []).join(', '));
    _conditions = TextEditingController(text: p?.conditions ?? '');
    _medications =
        TextEditingController(text: (p?.medications ?? const []).join(', '));
    _emergencyName =
        TextEditingController(text: p?.emergencyContactName ?? '');
    _emergencyPhone =
        TextEditingController(text: p?.emergencyContactPhone ?? '');
    _emergencyRel =
        TextEditingController(text: p?.emergencyContactRelationship ?? '');
    _birthDate = p?.birthDate;
    _gender = p?.gender;
    _bloodType = p?.bloodType;
  }

  @override
  void dispose() {
    _city.dispose();
    _phone.dispose();
    _alias.dispose();
    _allergies.dispose();
    _conditions.dispose();
    _medications.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    _emergencyRel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final profileId = widget.user.profile?.id;
    if (profileId == null) {
      _toast('No hay perfil para editar');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final payload = _buildPayload();
      if (payload.isEmpty) {
        _toast('No hay cambios para guardar');
        return;
      }
      await ref.read(profileApiProvider).update(profileId, payload);
      ref.invalidate(meProvider);
      if (!mounted) return;
      _toast('Perfil actualizado', success: true);
      context.pop();
    } catch (e) {
      _toast('No se pudo actualizar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, dynamic> _buildPayload() {
    final p = widget.user.profile;
    final payload = <String, dynamic>{};

    void putIfChanged(String key, String? original, String current) {
      final trimmed = current.trim();
      final orig = original?.trim() ?? '';
      if (trimmed != orig && trimmed.isNotEmpty) {
        payload[key] = trimmed;
      }
    }

    void putListIfChanged(
      String key,
      List<String>? original,
      String csv,
    ) {
      final parsed = _splitCsv(csv);
      final orig = original ?? const <String>[];
      final changed = parsed.length != orig.length ||
          !List.generate(parsed.length, (i) => parsed[i] == orig[i])
              .every((x) => x);
      if (changed && parsed.isNotEmpty) {
        payload[key] = parsed;
      }
    }

    putIfChanged('city', p?.city, _city.text);
    putIfChanged('phone', p?.phone, _phone.text);
    putIfChanged('alias', p?.alias, _alias.text);
    putIfChanged('conditions', p?.conditions, _conditions.text);
    putIfChanged(
      'emergencyContactName',
      p?.emergencyContactName,
      _emergencyName.text,
    );
    putIfChanged(
      'emergencyContactPhone',
      p?.emergencyContactPhone,
      _emergencyPhone.text,
    );
    putIfChanged(
      'emergencyContactRelationship',
      p?.emergencyContactRelationship,
      _emergencyRel.text,
    );

    putListIfChanged('allergies', p?.allergies, _allergies.text);
    putListIfChanged('medications', p?.medications, _medications.text);

    if (_birthDate != p?.birthDate && _birthDate != null) {
      payload['birthDate'] = _birthDate;
    }
    if (_gender != p?.gender && _gender != null) {
      payload['gender'] = _gender;
    }
    if (_bloodType != null && _bloodType != p?.bloodType) {
      payload['bloodType'] = _bloodType;
    }
    return payload;
  }

  static List<String> _splitCsv(String text) => text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  void _toast(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              success ? AppColors.brandGreen : AppColors.surfaceCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppTopBar.inner(
        title: 'Editar perfil',
        onBack: () => context.pop(),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              _SectionCard(
                title: 'Información personal',
                icon: Icons.person_outline,
                children: [
                  _BirthDateField(
                    value: _birthDate,
                    onChanged: (v) => setState(() => _birthDate = v),
                  ),
                  _GenderField(
                    value: _gender,
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  _Field(
                    label: 'Ciudad',
                    controller: _city,
                    hint: 'Santiago',
                    icon: Icons.location_city_outlined,
                  ),
                  _Field(
                    label: 'Teléfono',
                    controller: _phone,
                    hint: '+56912345678',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
                    ],
                  ),
                  _Field(
                    label: 'Alias',
                    controller: _alias,
                    hint: 'miguelangel',
                    icon: Icons.alternate_email,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Información médica',
                icon: Icons.medical_information_outlined,
                children: [
                  _BloodTypeField(
                    value: _bloodType,
                    onChanged: (v) => setState(() => _bloodType = v),
                  ),
                  _Field(
                    label: 'Alergias',
                    controller: _allergies,
                    hint: 'Penicilina, Polen',
                    icon: Icons.coronavirus_outlined,
                    helper: 'Separa con comas',
                  ),
                  _Field(
                    label: 'Condiciones',
                    controller: _conditions,
                    hint: 'Hipertensión, Diabetes tipo 2',
                    icon: Icons.healing_outlined,
                    maxLines: 3,
                  ),
                  _Field(
                    label: 'Medicamentos',
                    controller: _medications,
                    hint: 'Metformina 850mg, Losartán 50mg',
                    icon: Icons.medication_outlined,
                    helper: 'Separa con comas',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Contacto de emergencia',
                icon: Icons.emergency_outlined,
                children: [
                  _Field(
                    label: 'Nombre',
                    controller: _emergencyName,
                    hint: 'María González',
                    icon: Icons.person_outline,
                  ),
                  _Field(
                    label: 'Teléfono',
                    controller: _emergencyPhone,
                    hint: '+56987654321',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
                    ],
                  ),
                  _Field(
                    label: 'Relación',
                    controller: _emergencyRel,
                    hint: 'Madre',
                    icon: Icons.diversity_3_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        AppColors.brandGreen.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Guardar cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _saving ? null : () => context.pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.brandGreen, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final c in children) ...[
            c,
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.helper,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      cursorColor: AppColors.brandGreen,
      decoration: _decoration(label: label, hint: hint, helper: helper, icon: icon),
    );
  }
}

class _BloodTypeField extends StatelessWidget {
  const _BloodTypeField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final validValue =
        bloodTypeOptions.containsKey(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: validValue,
      isExpanded: true,
      dropdownColor: AppColors.surfaceCard,
      iconEnabledColor: AppColors.textMuted,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: _decoration(
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
      onChanged: onChanged,
    );
  }
}

class _GenderField extends StatelessWidget {
  const _GenderField({required this.value, required this.onChanged});

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
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: _decoration(label: 'Género', icon: Icons.wc_outlined),
      items: [
        for (final entry in genderOptions.entries)
          DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _BirthDateField extends StatelessWidget {
  const _BirthDateField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final parsed = hasValue ? DateTime.tryParse(value!) : null;
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: parsed ?? DateTime(now.year - 25),
          firstDate: DateTime(1900),
          lastDate: now,
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.brandGreen,
                onPrimary: Colors.black,
                surface: AppColors.surfaceCard,
                onSurface: AppColors.textPrimary,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: AppColors.surfaceCard,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          final iso = '${picked.year.toString().padLeft(4, '0')}-'
              '${picked.month.toString().padLeft(2, '0')}-'
              '${picked.day.toString().padLeft(2, '0')}';
          onChanged(iso);
        }
      },
      child: IgnorePointer(
        child: TextFormField(
          key: ValueKey(value),
          initialValue: hasValue ? value : '',
          enabled: false,
          style: TextStyle(
            color: hasValue ? AppColors.textPrimary : AppColors.textFaint,
            fontSize: 15,
          ),
          decoration: _decoration(
            label: 'Fecha de nacimiento',
            icon: Icons.cake_outlined,
            hint: 'YYYY-MM-DD',
          ).copyWith(
            suffixIcon: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.textMuted,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration({
  required String label,
  required IconData icon,
  String? hint,
  String? helper,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
    floatingLabelStyle: const TextStyle(
      color: AppColors.brandGreen,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 14),
    helperStyle: const TextStyle(color: AppColors.textFaint, fontSize: 12),
    prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
    filled: true,
    fillColor: AppColors.surfaceChip,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderChip),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderChip),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
    ),
  );
}
