import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../application/session_state.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  static const _sports = <_Sport>[
    _Sport('Fútbol', Icons.sports_soccer),
    _Sport('Básquetbol', Icons.sports_basketball),
    _Sport('Tenis', Icons.sports_tennis_outlined),
    _Sport('Trekking', Icons.terrain),
    _Sport('Running', Icons.directions_run),
    _Sport('Handball', Icons.sports_handball),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: const _BackgroundGlow()),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _LogoBadge(),
                      const SizedBox(height: 24),
                      const Text(
                        'RocketId',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Gestiona tus eventos deportivos',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 36),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          children: [
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final sport in _sports)
                                  _SportChip(sport: sport),
                              ],
                            ),
                            const SizedBox(height: 28),
                            sessionState == const SessionState.unknown()
                                ? const SizedBox(
                                    height: 56,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(sessionControllerProvider
                                                .notifier)
                                            .loginWithGoogle();
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          _GoogleGLogo(size: 22),
                                          SizedBox(width: 12),
                                          Text(
                                            'Continuar con Google',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 16),
                            const Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  color: AppColors.textFaint,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(text: 'Al continuar aceptas los '),
                                  TextSpan(
                                    text: 'Términos de uso',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: AppColors.textSoft,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      if (sessionState is SessionAuthenticated) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Ya has iniciado sesión',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            ref
                                .read(sessionControllerProvider.notifier)
                                .logout();
                          },
                          child: const Text('Cerrar sesión'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sport {
  final String label;
  final IconData icon;
  const _Sport(this.label, this.icon);
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 0.7,
            colors: [
              AppColors.brandGreen.withValues(alpha: 0.2),
              AppColors.scaffoldBg.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.brandGreen,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGreen.withValues(alpha: 0.45),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.rocket_launch,
        color: Colors.black,
        size: 44,
      ),
    );
  }
}

class _SportChip extends StatelessWidget {
  const _SportChip({required this.sport});
  final _Sport sport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceChip,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sport.icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            sport.label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo({this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);
  static const _blue = Color(0xFF4285F4);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;
    final radius = (size.width - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    double r(double deg) => deg * math.pi / 180;

    canvas.drawArc(rect, r(10), r(70), false, arc..color = _blue);
    canvas.drawArc(rect, r(80), r(90), false, arc..color = _green);
    canvas.drawArc(rect, r(170), r(90), false, arc..color = _yellow);
    canvas.drawArc(rect, r(260), r(95), false, arc..color = _red);

    final bar = Paint()..color = _blue;
    final barRect = Rect.fromLTRB(
      center.dx + radius * 0.05,
      center.dy - stroke * 0.5,
      center.dx + radius + stroke / 2,
      center.dy + stroke * 0.5,
    );
    canvas.drawRect(barRect, bar);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
