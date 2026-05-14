import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../shared/theme/app_colors.dart';
import '../auth/application/session_state.dart';
import 'widgets/onboarding_scaffold.dart';

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

  Future<void> _continue() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newAlias = _controller.text.trim();
    setState(() => _busy = true);
    try {
      if (_profileId != null && newAlias != (_initialAlias ?? '')) {
        await ref
            .read(profileApiProvider)
            .update(_profileId!, {'alias': newAlias});
      }
      await ref
          .read(sessionControllerProvider.notifier)
          .setOnboardingStep(2);
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
    final greeting =
        _firstName.isEmpty ? '¡Bienvenido al equipo!' : '¡Hola, $_firstName! Bienvenido al equipo.';
    return OnboardingScaffold(
      step: 1,
      totalSteps: 4,
      title: greeting,
      subtitle:
          '¿Con qué alias quieres que te encuentren tus amigos? Será tu nombre público en RocketId.',
      busy: _busy,
      primaryLabel: 'Continuar',
      onPrimary: _continue,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            LengthLimitingTextInputFormatter(20),
            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
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
            labelStyle: const TextStyle(color: AppColors.textMuted),
            floatingLabelStyle: const TextStyle(color: AppColors.brandGreen),
            filled: true,
            fillColor: AppColors.surfaceChip,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderChip),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderChip),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.brandGreen),
            ),
          ),
          validator: _validate,
          onFieldSubmitted: (_) => _continue(),
        ),
      ),
    );
  }
}
