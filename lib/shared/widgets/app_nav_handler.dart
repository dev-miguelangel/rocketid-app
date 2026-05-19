import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Maneja de forma centralizada los taps de [AppBottomNav].
///
/// Índices: 0 Inicio · 1 Agenda · 2 Actividad (crear) · 3 Contactos · 4 Perfil.
///
/// El índice 2 no navega: dispara [onCreateActivity] (abrir el formulario de
/// creación). Si no se pasa el callback, muestra un aviso temporal.
void handleNavTap(
  BuildContext context,
  int index, {
  required int currentIndex,
  VoidCallback? onCreateActivity,
}) {
  if (index == currentIndex) return;
  switch (index) {
    case 0:
      context.go('/inicio');
    case 1:
      context.go('/agenda');
    case 2:
      if (onCreateActivity != null) {
        onCreateActivity();
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Crear actividad estará disponible pronto'),
              backgroundColor: AppColors.surfaceCard,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    case 3:
      context.go('/contactos');
    case 4:
      context.go('/perfil');
  }
}
