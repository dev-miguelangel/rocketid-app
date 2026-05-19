import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../data/activities_api.dart';
import 'activity_widgets.dart';

/// Abre el selector de contactos para invitar participantes a una actividad.
/// Devuelve `true` si se enviaron invitaciones.
Future<bool?> openInviteParticipantsSheet(
  BuildContext context,
  String activityId,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => InviteParticipantsSheet(activityId: activityId),
  );
}

/// Hoja modal para invitar contactos a una actividad.
class InviteParticipantsSheet extends ConsumerStatefulWidget {
  const InviteParticipantsSheet({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<InviteParticipantsSheet> createState() =>
      _InviteParticipantsSheetState();
}

class _InviteParticipantsSheetState
    extends ConsumerState<InviteParticipantsSheet> {
  final Set<String> _selected = {};
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (_selected.isEmpty) {
      setState(() => _error = 'Selecciona al menos un contacto');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(activitiesApiProvider)
          .invite(widget.activityId, _selected.toList());
      ref.invalidate(activityParticipantsProvider(widget.activityId));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = activityErrorMessage(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No pudimos enviar las invitaciones';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final contactsAsync = ref.watch(myContactsProvider);

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderChip,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Invitar participantes',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: contactsAsync.when(
              loading: () => const ActivityLoadingState(),
              error: (_, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: ActivityErrorState(
                  onRetry: () => ref.invalidate(myContactsProvider),
                ),
              ),
              data: (contacts) {
                if (contacts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: ActivityEmptyState(
                      icon: Icons.contacts_outlined,
                      title: 'Sin contactos',
                      subtitle:
                          'Agrega contactos para poder invitarlos a tus '
                          'actividades.',
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: contacts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final contact = contacts[i];
                    final name = contact.displayName;
                    final selected = _selected.contains(contact.id);
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _saving
                          ? null
                          : () => setState(() {
                                if (selected) {
                                  _selected.remove(contact.id);
                                } else {
                                  _selected.add(contact.id);
                                }
                              }),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceChip,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.brandGreen
                                : AppColors.borderChip,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 20,
                              color: selected
                                  ? AppColors.brandGreen
                                  : AppColors.textFaint,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              16 + media.padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: AppColors.notificationDot,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          _selected.isEmpty
                              ? 'Invitar'
                              : 'Invitar (${_selected.length})',
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
