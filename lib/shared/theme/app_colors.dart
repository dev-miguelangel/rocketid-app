import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Tokens de color de la app. Los valores son mutables: `apply` los reemplaza
/// al cambiar de estilo en runtime (ver `ThemeController`). Tras un cambio, el
/// árbol de widgets se reconstruye por completo para tomar los nuevos valores.
abstract final class AppColors {
  static Color brandGreen = _initial.brandGreen;
  static Color scaffoldBg = _initial.scaffoldBg;
  static Color surfaceCard = _initial.surfaceCard;
  static Color surfaceChip = _initial.surfaceChip;
  static Color borderSubtle = _initial.borderSubtle;
  static Color borderChip = _initial.borderChip;
  static Color textPrimary = _initial.textPrimary;
  static Color textSecondary = _initial.textSecondary;
  static Color textMuted = _initial.textMuted;
  static Color textFaint = _initial.textFaint;
  static Color textSoft = _initial.textSoft;
  static Color notificationDot = _initial.notificationDot;

  static const PaletteTokens _initial = PaletteTokens(
    scaffoldBg: Color(0xFF0A0A0A),
    surfaceCard: Color(0xFF161616),
    surfaceChip: Color(0xFF1F1F1F),
    borderSubtle: Color(0xFF1F1F1F),
    borderChip: Color(0xFF2A2A2A),
    brandGreen: Color(0xFF34D399),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFE5E7EB),
    textMuted: Color(0xFF9CA3AF),
    textFaint: Color(0xFF6B7280),
    textSoft: Color(0xFFD1D5DB),
    notificationDot: Color(0xFFEF4444),
  );

  /// Reemplaza todos los tokens por los de la paleta [id].
  static void apply(AppPaletteId id) {
    final t = kPalettes[id]!;
    brandGreen = t.brandGreen;
    scaffoldBg = t.scaffoldBg;
    surfaceCard = t.surfaceCard;
    surfaceChip = t.surfaceChip;
    borderSubtle = t.borderSubtle;
    borderChip = t.borderChip;
    textPrimary = t.textPrimary;
    textSecondary = t.textSecondary;
    textMuted = t.textMuted;
    textFaint = t.textFaint;
    textSoft = t.textSoft;
    notificationDot = t.notificationDot;
  }
}
