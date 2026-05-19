import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../domain/pending_action.dart';
import 'pending_quick_actions_sheet.dart';

/// Ítem de la lista de pendientes. Replica la estructura de `ActivityListTile`:
/// fila superior con un chip de tipo y el botón de acciones rápidas (⚡),
/// seguida del título y los metadatos.
class PendingActionTile extends StatelessWidget {
  const PendingActionTile({super.key, required this.action});

  final PendingAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openPendingQuickActionsSheet(context, action),
        child: Container(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _KindChip(action.kind),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        openPendingQuickActionsSheet(context, action),
                    tooltip: 'Acciones rápidas',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.bolt),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.brandGreen,
                      backgroundColor:
                          AppColors.brandGreen.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                action.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (action.subtitle != null) ...[
                const SizedBox(height: 8),
                _MetaRow(icon: Icons.info_outline, text: action.subtitle!),
              ],
              const SizedBox(height: 4),
              _MetaRow(
                icon: Icons.schedule,
                text: 'Recibida ${_relativeTime(action.createdAt)}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiempo relativo en español: `hoy`, `ayer`, `hace 3 días`, `hace 2 semanas`.
String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 14) return 'hace ${diff.inDays ~/ 7} semanas';
  if (diff.inDays >= 7) return 'hace una semana';
  if (diff.inDays >= 2) return 'hace ${diff.inDays} días';
  if (diff.inDays == 1) return 'ayer';
  if (diff.inHours >= 1) return 'hace ${diff.inHours} h';
  if (diff.inMinutes >= 1) return 'hace ${diff.inMinutes} min';
  return 'recién';
}

/// Chip de tipo de pendiente, con el estilo verde de los chips de actividad.
class _KindChip extends StatelessWidget {
  const _KindChip(this.kind);

  final PendingActionKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        kind.chipLabel,
        style: TextStyle(
          color: AppColors.brandGreen,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
