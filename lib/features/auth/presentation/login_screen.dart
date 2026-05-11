import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';
import '../application/session_state.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionControllerProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.rocket_launch,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 24),
              const Text(
                'RocketID',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              sessionState == const SessionState.unknown()
                  ? const CircularProgressIndicator()
                  : FilledButton.icon(
                      onPressed: () {
                        ref.read(sessionControllerProvider.notifier).loginWithGoogle();
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Iniciar sesión con Google'),
                    ),
              if (sessionState is SessionAuthenticated) ...[
                const Text('Ya has iniciado sesión'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    ref.read(sessionControllerProvider.notifier).logout();
                  },
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}