import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Identificador de cada estilo de color disponible en la app.
///
/// El valor de [storageKey] es lo que se persiste; no cambiarlo sin migrar la
/// preferencia guardada de los usuarios.
enum AppPaletteId {
  emerald('emerald', 'Emerald Nocturne', Brightness.dark),
  indigo('indigo', 'Indigo Pulse', Brightness.dark),
  aurora('aurora', 'Aurora Clear', Brightness.light);

  const AppPaletteId(this.storageKey, this.label, this.brightness);

  /// Clave persistida en almacenamiento seguro.
  final String storageKey;

  /// Nombre mostrado en la pantalla de Ajustes.
  final String label;

  /// Claro u oscuro: determina los iconos de la barra de estado.
  final Brightness brightness;

  /// Resuelve un [AppPaletteId] desde su [storageKey]; `emerald` por defecto.
  static AppPaletteId fromKey(String? key) {
    for (final id in AppPaletteId.values) {
      if (id.storageKey == key) return id;
    }
    return AppPaletteId.emerald;
  }
}

/// Los 12 tokens de color que componen un estilo. Mismos nombres que los
/// campos de `AppColors`, que copia estos valores al aplicar una paleta.
class PaletteTokens {
  const PaletteTokens({
    required this.scaffoldBg,
    required this.surfaceCard,
    required this.surfaceChip,
    required this.borderSubtle,
    required this.borderChip,
    required this.brandGreen,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.textSoft,
    required this.notificationDot,
  });

  final Color scaffoldBg;
  final Color surfaceCard;
  final Color surfaceChip;
  final Color borderSubtle;
  final Color borderChip;

  /// Color de acento / acción. Conserva el nombre histórico `brandGreen`
  /// aunque en Indigo y Aurora no sea verde.
  final Color brandGreen;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;
  final Color textSoft;
  final Color notificationDot;
}

/// Definición de las tres paletas. Prototipadas en `docs/estilos-colores.html`.
const Map<AppPaletteId, PaletteTokens> kPalettes = {
  AppPaletteId.emerald: PaletteTokens(
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
  ),
  AppPaletteId.indigo: PaletteTokens(
    scaffoldBg: Color(0xFF0B0B12),
    surfaceCard: Color(0xFF15151F),
    surfaceChip: Color(0xFF23232F),
    borderSubtle: Color(0xFF23232F),
    borderChip: Color(0xFF2E2E3C),
    brandGreen: Color(0xFF6366F1),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFE2E2EE),
    textMuted: Color(0xFF9499B7),
    textFaint: Color(0xFF6B6F8C),
    textSoft: Color(0xFFC7CBDF),
    notificationDot: Color(0xFFF87171),
  ),
  AppPaletteId.aurora: PaletteTokens(
    scaffoldBg: Color(0xFFF5F7FA),
    surfaceCard: Color(0xFFFFFFFF),
    surfaceChip: Color(0xFFE8EDF3),
    borderSubtle: Color(0xFFE8EDF3),
    borderChip: Color(0xFFD6DEE8),
    brandGreen: Color(0xFF0EA5E9),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF1E293B),
    textMuted: Color(0xFF64748B),
    textFaint: Color(0xFF94A3B8),
    textSoft: Color(0xFF475569),
    notificationDot: Color(0xFFDC2626),
  ),
};

/// Estilo de barra de estado/navegación coherente con la paleta dada.
SystemUiOverlayStyle systemOverlayFor(AppPaletteId id) {
  final tokens = kPalettes[id]!;
  final isDark = id.brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: tokens.scaffoldBg,
    systemNavigationBarIconBrightness:
        isDark ? Brightness.light : Brightness.dark,
  );
}
