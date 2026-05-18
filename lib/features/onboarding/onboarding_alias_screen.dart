import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/theme/app_colors.dart';
import '../auth/application/session_state.dart';

class OnboardingAliasScreen extends ConsumerStatefulWidget {
  const OnboardingAliasScreen({super.key});

  @override
  ConsumerState<OnboardingAliasScreen> createState() =>
      _OnboardingAliasScreenState();
}

class _OnboardingAliasScreenState extends ConsumerState<OnboardingAliasScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _initialAlias;
  String? _profileId;
  String _firstName = '';

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionControllerProvider);
    if (session is SessionAuthenticated) {
      _initialAlias = session.user.profile?.alias;
      _profileId = session.user.profile?.id;
      _controller.text = _initialAlias ?? '';
      final name = session.user.name?.trim();
      _firstName = (name != null && name.isNotEmpty)
          ? name.split(' ').first
          : session.user.email.split('@').first;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return 'Escribe un alias';
    if (v.length < 3) return 'Mínimo 3 caracteres';
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v)) {
      return 'Solo minúsculas, números y guion bajo';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newAlias = _controller.text.trim();
    setState(() => _busy = true);
    try {
      if (_profileId != null && newAlias != (_initialAlias ?? '')) {
        await ref.read(profileApiProvider).update(_profileId!, {
          'alias': newAlias,
        });
      }
      if (!mounted) return;
      context.go('/onboarding/personal');
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 409
          ? 'Ese alias ya está en uso'
          : 'No se pudo guardar el alias';
      _toast(msg);
    } catch (_) {
      _toast('No se pudo guardar el alias');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _WelcomeGlow()),
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
                      const SizedBox(height: 28),
                      Text(
                        _firstName.isEmpty
                            ? '¡Bienvenido!'
                            : '¡Bienvenido, $_firstName!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Te uniste al equipo de RocketId.\nGestiona tus eventos deportivos en un solo lugar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: const Column(
                          children: [
                            _FeatureRow(
                              icon: Icons.event_available_outlined,
                              text: 'Crea y gestiona eventos',
                            ),
                            SizedBox(height: 14),
                            _FeatureRow(
                              icon: Icons.groups_2_outlined,
                              text: 'Organiza equipos y contactos',
                            ),
                            SizedBox(height: 14),
                            _FeatureRow(
                              icon: Icons.directions_run,
                              text: 'Registra tu actividad deportiva',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '¿Con qué alias quieres que te encuentren las personas?',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: TextFormField(
                          controller: _controller,
                          autofocus: false,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(20),
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-z0-9_]'),
                            ),
                          ],
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: AppColors.brandGreen,
                          decoration: InputDecoration(
                            labelText: 'Alias',
                            prefixIcon: const Icon(
                              Icons.alternate_email,
                              color: AppColors.textMuted,
                            ),
                            labelStyle: const TextStyle(
                              color: AppColors.textMuted,
                            ),
                            floatingLabelStyle: const TextStyle(
                              color: AppColors.brandGreen,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceChip,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.borderChip,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.borderChip,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.brandGreen,
                              ),
                            ),
                          ),
                          validator: _validate,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Comencemos',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
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

class _WelcomeGlow extends StatelessWidget {
  const _WelcomeGlow();

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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceChip,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderChip),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.brandGreen, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
