import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'routing/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final palette = ref.watch(themeControllerProvider);

    // La `ValueKey` cambia con la paleta y fuerza la reconstrucción completa
    // del árbol, para que cada widget vuelva a leer los tokens de `AppColors`.
    return MaterialApp.router(
      key: ValueKey(palette),
      title: 'RocketID',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: palette.brightness,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
