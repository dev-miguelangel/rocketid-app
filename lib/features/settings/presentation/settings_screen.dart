import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_palette.dart';
import '../../../shared/widgets/app_top_bar.dart';

/// Pantalla de Ajustes. Hoy solo contiene el selector de estilo de color.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppTopBar.inner(title: 'Ajustes'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined,
                  color: AppColors.brandGreen, size: 20),
              const SizedBox(width: 10),
              Text(
                'Apariencia',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Elige el estilo de color de la app.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          for (final id in AppPaletteId.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PaletteOption(
                id: id,
                selected: id == current,
                onTap: () =>
                    ref.read(themeControllerProvider.notifier).setPalette(id),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fila seleccionable de una paleta: swatches + nombre + check.
class _PaletteOption extends StatelessWidget {
  const _PaletteOption({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  final AppPaletteId id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = kPalettes[id]!;
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.brandGreen : AppColors.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _Swatches(tokens: tokens),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id.label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      id.brightness == Brightness.dark
                          ? 'Tema oscuro'
                          : 'Tema claro',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color:
                    selected ? AppColors.brandGreen : AppColors.borderChip,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini muestrario de 4 colores representativos de una paleta.
class _Swatches extends StatelessWidget {
  const _Swatches({required this.tokens});

  final PaletteTokens tokens;

  @override
  Widget build(BuildContext context) {
    final colors = [
      tokens.scaffoldBg,
      tokens.surfaceCard,
      tokens.brandGreen,
      tokens.textPrimary,
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderChip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in colors)
              Container(width: 14, height: 44, color: c),
          ],
        ),
      ),
    );
  }
}
