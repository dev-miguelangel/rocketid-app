import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app.dart';
import 'core/storage/secure_storage.dart';
import 'features/settings/application/theme_controller.dart';
import 'providers.dart';
import 'shared/theme/app_colors.dart';
import 'shared/theme/app_palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Rutas limpias en web (`/inicio` en vez de `/#/inicio`). Requiere SPA
    // fallback en el servidor: ver `nginx.conf`.
    usePathUrlStrategy();
  }

  // Resuelve el estilo guardado antes del primer frame para evitar parpadeo.
  final storage = SecureStorage();
  final palette = AppPaletteId.fromKey(await storage.themePreference);
  AppColors.apply(palette);
  SystemChrome.setSystemUIOverlayStyle(systemOverlayFor(palette));

  runApp(
    ProviderScope(
      overrides: [
        themeControllerProvider.overrideWith(
          (ref) => ThemeController(ref.watch(secureStorageProvider), palette),
        ),
      ],
      child: const App(),
    ),
  );
}
