import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/theme/app_colors.dart';
import '../domain/activity.dart';
import 'invite_participants_sheet.dart';

/// Abre la hoja de un cupo libre del tablero de subequipos.
///
/// Devuelve `true` si se enviaron invitaciones a contactos (el tablero debe
/// recargar y redistribuir a los nuevos invitados).
Future<bool?> openCupoInviteSheet(
  BuildContext context, {
  required Activity activity,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CupoInviteSheet(activity: activity),
  );
}

class _CupoInviteSheet extends StatelessWidget {
  const _CupoInviteSheet({required this.activity});

  final Activity activity;

  Future<void> _inviteContacts(BuildContext context) async {
    // La hoja de selección de contactos se abre encima de esta; al cerrarse,
    // propagamos el resultado para que el tablero recargue.
    final ok = await openInviteParticipantsSheet(context, activity.id);
    if (context.mounted) Navigator.of(context).pop(ok == true);
  }

  Future<void> _inviteWhatsapp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final aliasRaw = activity.organizerAlias?.trim();
    final alias = aliasRaw != null && aliasRaw.isNotEmpty
        ? aliasRaw
        : (activity.organizer?.displayName ?? 'Alguien');
    final message =
        '¡Hola! $alias te invita a participar en "${activity.displayTitle}" '
        'en RocketID. Descarga la app y regístrate para unirte.';
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    navigator.pop(false);
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('No se pudo abrir WhatsApp'),
            backgroundColor: AppColors.surfaceCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + media.padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderChip,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Llenar cupo libre',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Invita a alguien a unirse a esta actividad.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            if (activity.allowExternals) ...[
              _OptionTile(
                icon: Icons.contacts_outlined,
                title: 'Invitar a un contacto',
                subtitle: 'Envía una invitación a tus contactos de RocketID.',
                onTap: () => _inviteContacts(context),
              ),
              const SizedBox(height: 10),
            ],
            _OptionTile(
              icon: Icons.chat,
              title: 'Invitar por WhatsApp',
              subtitle: 'Comparte un mensaje para que se registren y participen.',
              onTap: () => _inviteWhatsapp(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceChip,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderChip),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.brandGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
