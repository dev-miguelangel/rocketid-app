import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import 'team_icons.dart';

/// Convierte un hex `#RRGGBB` (o `RRGGBB`) en [Color]. Si no se puede parsear,
/// devuelve el verde de marca.
Color parseTeamColor(String? hex) {
  if (hex == null) return AppColors.brandGreen;
  var clean = hex.trim().replaceAll('#', '');
  if (clean.length == 3) {
    clean = clean.split('').map((c) => '$c$c').join();
  }
  if (clean.length == 8) {
    final value = int.tryParse(clean, radix: 16);
    if (value != null) return Color(value);
  }
  if (clean.length == 6) {
    final value = int.tryParse(clean, radix: 16);
    if (value != null) return Color(0xFF000000 | value);
  }
  return AppColors.brandGreen;
}

/// Color de primer plano (icono) legible sobre [bg].
Color onTeamColor(Color bg) =>
    bg.computeLuminance() > 0.55 ? Colors.black : Colors.white;

/// Logo de un equipo: cuadrado redondeado con fondo de color e icono Material.
class TeamLogo extends StatelessWidget {
  const TeamLogo({
    super.key,
    required this.icon,
    required this.colorHex,
    this.size = 48,
    this.radius = 14,
  });

  final String icon;
  final String colorHex;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bg = parseTeamColor(colorHex);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        resolveTeamIcon(icon),
        color: onTeamColor(bg),
        size: size * 0.52,
      ),
    );
  }
}
