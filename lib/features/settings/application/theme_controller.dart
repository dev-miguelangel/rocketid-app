import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_palette.dart';

/// Controla el estilo de color activo y lo persiste.
///
/// El valor inicial lo resuelve `main` desde almacenamiento seguro y se inyecta
/// vía override del provider, de modo que el primer frame ya usa la paleta
/// correcta sin parpadeo.
class ThemeController extends StateNotifier<AppPaletteId> {
  ThemeController(this._storage, AppPaletteId initial) : super(initial);

  final SecureStorage _storage;

  /// Cambia la paleta activa, actualiza `AppColors`, la barra de sistema y
  /// persiste la elección. El rebuild del árbol lo dispara `App` al observar
  /// este `state`.
  Future<void> setPalette(AppPaletteId id) async {
    if (id == state) return;
    AppColors.apply(id);
    SystemChrome.setSystemUIOverlayStyle(systemOverlayFor(id));
    state = id;
    await _storage.setThemePreference(id.storageKey);
  }
}
