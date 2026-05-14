import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../auth/domain/user.dart';

final meProvider = FutureProvider.autoDispose<User>((ref) async {
  final authApi = ref.watch(authApiProvider);
  return authApi.me();
});

// La clave es el valor del enum BloodType del backend (lo que la API valida y
// guarda, p. ej. "A+", "A-"); el valor del map es solo la etiqueta a mostrar.
const bloodTypeOptions = <String, String>{
  'O+': 'O+',
  'O-': 'O−',
  'A+': 'A+',
  'A-': 'A−',
  'B+': 'B+',
  'B-': 'B−',
  'AB+': 'AB+',
  'AB-': 'AB−',
  'sin informacion': 'sin informacion',
};

String? bloodTypeLabel(String? code) =>
    code == null ? null : (bloodTypeOptions[code] ?? code);

const genderOptions = <String, String>{
  'male': 'Masculino',
  'female': 'Femenino',
  'other': 'Otro',
};

String? genderLabel(String? code) =>
    code == null ? null : (genderOptions[code] ?? code);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(meProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppTopBar.inner(title: 'Perfil'),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4,
        onTap: (i) {
          if (i == 4) return;
          if (i == 0) {
            context.go('/inicio');
            return;
          }
          if (i == 3) {
            context.go('/contactos');
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Esta sección estará disponible pronto'),
                backgroundColor: AppColors.surfaceCard,
                behavior: SnackBarBehavior.floating,
              ),
            );
        },
      ),
      body: meAsync.when(
        data: (user) => RefreshIndicator(
          color: AppColors.brandGreen,
          backgroundColor: AppColors.surfaceCard,
          onRefresh: () => ref.refresh(meProvider.future),
          child: _ProfileBody(user: user),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandGreen),
        ),
        error: (err, _) => _ErrorState(
          error: err,
          onRetry: () => ref.invalidate(meProvider),
          onLogout: () => ref.read(sessionControllerProvider.notifier).logout(),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = user.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        _Header(user: user),
        const SizedBox(height: 20),
        _Section(
          title: 'Información personal',
          icon: Icons.person_outline,
          onEdit: user.profile == null
              ? null
              : () => context.push('/perfil/editar/personal', extra: user),
          rows: [
            _Row(
              icon: Icons.cake_outlined,
              label: 'Fecha de nacimiento',
              value: profile?.birthDate,
            ),
            _Row(
              icon: Icons.wc_outlined,
              label: 'Género',
              value: genderLabel(profile?.gender),
            ),
            _Row(
              icon: Icons.location_city_outlined,
              label: 'Ciudad',
              value: profile?.city,
            ),
            _Row(
              icon: Icons.phone_outlined,
              label: 'Teléfono',
              value: profile?.phone,
            ),
            _Row(
              icon: Icons.alternate_email,
              label: 'Alias',
              value: profile?.alias,
            ),
            _Row(
              icon: Icons.badge_outlined,
              label: 'ID',
              value: profile?.stringId,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Información médica',
          icon: Icons.medical_information_outlined,
          onEdit: user.profile == null
              ? null
              : () => context.push('/perfil/editar/medica', extra: user),
          rows: [
            _Row(
              icon: Icons.bloodtype_outlined,
              label: 'Tipo de sangre',
              value: bloodTypeLabel(profile?.bloodType),
            ),
            _Row(
              icon: Icons.coronavirus_outlined,
              label: 'Alergias',
              value: _joinList(profile?.allergies),
            ),
            _Row(
              icon: Icons.healing_outlined,
              label: 'Condiciones',
              value: profile?.conditions,
            ),
            _Row(
              icon: Icons.medication_outlined,
              label: 'Medicamentos',
              value: _joinList(profile?.medications),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Contacto de emergencia',
          icon: Icons.emergency_outlined,
          onEdit: user.profile == null
              ? null
              : () => context.push('/perfil/editar/emergencia', extra: user),
          rows: [
            _Row(
              icon: Icons.person_outline,
              label: 'Nombre',
              value: profile?.emergencyContactName,
            ),
            _Row(
              icon: Icons.phone_outlined,
              label: 'Teléfono',
              value: profile?.emergencyContactPhone,
            ),
            _Row(
              icon: Icons.diversity_3_outlined,
              label: 'Relación',
              value: profile?.emergencyContactRelationship,
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.notificationDot,
              side: const BorderSide(color: AppColors.borderChip),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              await ref.read(sessionControllerProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout, size: 20),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  static String? _joinList(List<String>? values) {
    if (values == null || values.isEmpty) return null;
    return values.join(', ');
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final displayName = user.name ?? user.email.split('@').first;
    final alias = user.profile?.alias;
    final stringId = user.profile?.stringId;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          _Avatar(url: user.avatar, fallback: displayName),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (alias != null || stringId != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (alias != null) _Tag(text: '@$alias'),
                      if (stringId != null) _Tag(text: stringId),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.fallback});

  final String? url;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final initial = fallback.trim().isEmpty
        ? 'R'
        : fallback.trim()[0].toUpperCase();

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.brandGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.isNotEmpty
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initialChild(initial),
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : _initialChild(initial),
            )
          : _initialChild(initial),
    );
  }

  Widget _initialChild(String initial) => Center(
    child: Text(
      initial,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 26,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceChip,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderChip),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.rows,
    this.onEdit,
  });

  final String title;
  final IconData icon;
  final List<_Row> rows;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 8),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  tooltip: 'Editar',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(children: [for (final r in rows) r]),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final shown = (value == null || value!.trim().isEmpty)
        ? 'No especificado'
        : value!;
    final isEmpty = value == null || value!.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shown,
                  style: TextStyle(
                    color: isEmpty
                        ? AppColors.textFaint
                        : AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
    required this.onLogout,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.notificationDot,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'No pudimos cargar tu perfil',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onRetry,
            child: const Text(
              'Reintentar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onLogout,
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
