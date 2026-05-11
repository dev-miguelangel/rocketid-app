import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../auth/application/session_state.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurple.shade100,
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 24),
              switch (sessionState) {
                SessionAuthenticated() => Column(
                    children: [
                      Text(
                        sessionState.user.profile?.name ?? sessionState.user.email,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sessionState.user.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                _ => const Text('Cargando...'),
              },
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () {
                  ref.read(sessionControllerProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}