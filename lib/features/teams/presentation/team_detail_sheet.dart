import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../contacts/domain/contact.dart';
import '../../profile/profile_screen.dart' show meProvider;
import '../data/teams_api.dart';
import '../domain/team.dart';
import 'team_form_sheet.dart';
import 'team_logo.dart';
import 'team_widgets.dart';

class TeamDetailSheet extends ConsumerStatefulWidget {
  const TeamDetailSheet({super.key, required this.teamId, this.initial});

  final String teamId;
  final Team? initial;

  @override
  ConsumerState<TeamDetailSheet> createState() => _TeamDetailSheetState();
}

class _TeamDetailSheetState extends ConsumerState<TeamDetailSheet> {
  bool _busy = false;
  String _result = '';

  String get _teamId => widget.teamId;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.surfaceCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _refreshAll() {
    ref.invalidate(teamDetailProvider(_teamId));
    ref.invalidate(teamMembersProvider(_teamId));
    ref.invalidate(teamRequestsProvider(_teamId));
    ref.invalidate(myTeamsProvider);
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
        content:
            Text(message, style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action,
                style: TextStyle(
                    color: AppColors.notificationDot,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _edit(Team team) async {
    final updated = await showModalBottomSheet<Team>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TeamFormSheet(existing: team),
    );
    if (!mounted) return;
    if (updated != null) {
      _result = 'updated';
      ref.invalidate(teamDetailProvider(_teamId));
      ref.invalidate(myTeamsProvider);
      _toast('Equipo actualizado');
    }
  }

  Future<void> _addMember(Set<String> existing) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTeamMemberSheet(
        teamId: _teamId,
        existingUserIds: existing,
      ),
    );
    if (!mounted) return;
    if (added == true) {
      _result = 'updated';
      ref.invalidate(teamMembersProvider(_teamId));
      ref.invalidate(teamDetailProvider(_teamId));
      ref.invalidate(myTeamsProvider);
      _toast('Miembro agregado');
    }
  }

  Future<void> _changeRole(TeamMember member, String newRole) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(teamsApiProvider)
          .updateMemberRole(_teamId, member.userId, newRole);
      if (!mounted) return;
      _result = 'updated';
      ref.invalidate(teamMembersProvider(_teamId));
      _toast(newRole == 'captain'
          ? '${member.user.displayName} ahora es capitán'
          : '${member.user.displayName} ahora es miembro');
    } on DioException catch (e) {
      _toast(teamErrorMessage(e));
    } catch (_) {
      _toast('No pudimos cambiar el rol');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeMember(TeamMember member) async {
    final ok = await _confirm(
      'Quitar miembro',
      '¿Quitar a ${member.user.displayName} del equipo?',
      'Quitar',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(teamsApiProvider).removeMember(_teamId, member.userId);
      if (!mounted) return;
      _result = 'updated';
      ref.invalidate(teamMembersProvider(_teamId));
      ref.invalidate(teamDetailProvider(_teamId));
      ref.invalidate(myTeamsProvider);
      _toast('${member.user.displayName} se quitó del equipo');
    } on DioException catch (e) {
      _toast(teamErrorMessage(e));
    } catch (_) {
      _toast('No pudimos quitar al miembro');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _respondRequest(TeamMember member, bool accept) async {
    setState(() => _busy = true);
    try {
      final api = ref.read(teamsApiProvider);
      if (accept) {
        await api.acceptRequest(_teamId, member.userId);
      } else {
        await api.rejectRequest(_teamId, member.userId);
      }
      if (!mounted) return;
      _result = 'updated';
      _refreshAll();
      _toast(accept
          ? '${member.user.displayName} se unió al equipo'
          : 'Solicitud de ${member.user.displayName} rechazada');
    } on DioException catch (e) {
      _toast(teamErrorMessage(e));
    } catch (_) {
      _toast('No pudimos procesar la solicitud');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    final ok = await _confirm(
      'Salir del equipo',
      '¿Seguro que quieres salir de este equipo?',
      'Salir',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(teamsApiProvider).leave(_teamId);
      if (!mounted) return;
      ref.invalidate(myTeamsProvider);
      Navigator.of(context).pop('left');
    } on DioException catch (e) {
      _toast(teamErrorMessage(e));
      if (mounted) setState(() => _busy = false);
    } catch (_) {
      _toast('No pudimos completar la acción');
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await _confirm(
      'Eliminar equipo',
      'Esta acción no se puede deshacer.',
      'Eliminar',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(teamsApiProvider).delete(_teamId);
      if (!mounted) return;
      ref.invalidate(myTeamsProvider);
      Navigator.of(context).pop('deleted');
    } on DioException catch (e) {
      _toast(teamErrorMessage(e));
      if (mounted) setState(() => _busy = false);
    } catch (_) {
      _toast('No pudimos eliminar el equipo');
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final detailAsync = ref.watch(teamDetailProvider(_teamId));
    final team = detailAsync.maybeWhen(
      data: (t) => t,
      orElse: () => widget.initial,
    );
    final me = ref.watch(meProvider).valueOrNull;
    final myId = me?.id;

    final membersAsync = ref.watch(teamMembersProvider(_teamId));
    final members = membersAsync.valueOrNull ?? const <TeamMember>[];
    String? myRole;
    for (final m in members) {
      if (m.userId == myId) {
        myRole = m.role;
        break;
      }
    }
    final isOwner =
        team?.ownerId != null && myId != null && team!.ownerId == myId;
    final canManage = isOwner || myRole == 'captain';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_result.isEmpty ? null : _result);
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 4, 10),
              child: Row(
                children: [
                  TeamLogo(
                    icon: team?.icon ?? 'groups',
                    colorHex: team?.color ?? '#34D399',
                    size: 36,
                    radius: 11,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      team?.name ?? 'Equipo',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (canManage && team != null)
                    IconButton(
                      tooltip: 'Editar equipo',
                      onPressed: _busy ? null : () => _edit(team),
                      icon: Icon(Icons.edit_outlined,
                          color: AppColors.textMuted),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context)
                        .pop(_result.isEmpty ? null : _result),
                    icon: Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: AppColors.borderSubtle),
            Flexible(
              child: detailAsync.when(
                data: (t) => _buildBody(
                  t,
                  members: members,
                  membersAsync: membersAsync,
                  canManage: canManage,
                  isOwner: isOwner,
                  myRole: myRole,
                  myId: myId,
                  bottomInset: media.padding.bottom,
                ),
                loading: () => Padding(
                  padding: EdgeInsets.symmetric(vertical: 56),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.brandGreen),
                  ),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: TeamInlineErrorCard(
                    error: err,
                    onRetry: () => ref.invalidate(teamDetailProvider(_teamId)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    Team team, {
    required List<TeamMember> members,
    required AsyncValue<List<TeamMember>> membersAsync,
    required bool canManage,
    required bool isOwner,
    required String? myRole,
    required String? myId,
    required double bottomInset,
  }) {
    final existingUserIds = members.map((m) => m.userId).toSet();
    final children = <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (team.sportLabel.isNotEmpty)
            _Chip(icon: Icons.sports_outlined, text: team.sportLabel),
          _Chip(icon: Icons.wc_outlined, text: genderLabel(team.gender)),
          _Chip(
            icon: Icons.people_outline,
            text: '${members.isNotEmpty ? members.length : (team.memberCount ?? 0)} '
                '${(members.isNotEmpty ? members.length : (team.memberCount ?? 0)) == 1 ? 'miembro' : 'miembros'}',
          ),
        ],
      ),
      if (team.description != null && team.description!.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text(
          team.description!,
          style: TextStyle(color: AppColors.textSoft, fontSize: 14, height: 1.4),
        ),
      ],
      const SizedBox(height: 20),
      const TeamSectionLabel('MIEMBROS'),
      const SizedBox(height: 10),
    ];

    if (canManage) {
      children
        ..add(SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandGreen,
              side: BorderSide(color: AppColors.borderChip),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _busy ? null : () => _addMember(existingUserIds),
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text('Agregar miembro',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ))
        ..add(const SizedBox(height: 12));
    }

    children.addAll(
      membersAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const [
              TeamInfoCard(icon: Icons.group_outlined, text: 'Aún no hay miembros.'),
            ];
          }
          return [
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _MemberTile(
                member: list[i],
                canManage: canManage && list[i].userId != myId && !list[i].isOwner,
                busy: _busy,
                onMakeCaptain: () => _changeRole(list[i], 'captain'),
                onMakeMember: () => _changeRole(list[i], 'member'),
                onRemove: () => _removeMember(list[i]),
              ),
            ],
          ];
        },
        loading: () => const [TeamLoadingCard()],
        error: (err, _) => [
          TeamInlineErrorCard(
            error: err,
            onRetry: () => ref.invalidate(teamMembersProvider(_teamId)),
          ),
        ],
      ),
    );

    if (canManage) {
      children
        ..add(const SizedBox(height: 22))
        ..add(const TeamSectionLabel('SOLICITUDES PENDIENTES'))
        ..add(const SizedBox(height: 10))
        ..add(_RequestsSection(
          teamId: _teamId,
          busy: _busy,
          onAccept: (m) => _respondRequest(m, true),
          onReject: (m) => _respondRequest(m, false),
        ));
    }

    children.add(const SizedBox(height: 24));
    if (isOwner) {
      children.add(SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.notificationDot,
            side: BorderSide(color: AppColors.borderChip),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _busy ? null : _delete,
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Eliminar equipo',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ));
    } else if (myRole != null) {
      children.add(SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.notificationDot,
            side: BorderSide(color: AppColors.borderChip),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _busy ? null : _leave,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Salir del equipo',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ));
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
      children: children,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.canManage,
    required this.busy,
    required this.onMakeCaptain,
    required this.onMakeMember,
    required this.onRemove,
  });

  final TeamMember member;
  final bool canManage;
  final bool busy;
  final VoidCallback onMakeCaptain;
  final VoidCallback onMakeMember;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = member.user;
    final subtitle = _subtitle(c);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            TeamMemberAvatar(url: c.avatar, initial: c.initial),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          c.displayName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TeamRoleBadge(role: member.role),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (canManage)
              PopupMenuButton<String>(
                enabled: !busy,
                color: AppColors.surfaceCard,
                icon: Icon(Icons.more_vert, color: AppColors.textMuted),
                onSelected: (v) {
                  switch (v) {
                    case 'captain':
                      onMakeCaptain();
                    case 'member':
                      onMakeMember();
                    case 'remove':
                      onRemove();
                  }
                },
                itemBuilder: (_) => [
                  if (member.role != 'captain')
                    PopupMenuItem(
                      value: 'captain',
                      child: Text('Hacer capitán',
                          style: TextStyle(color: AppColors.textPrimary)),
                    ),
                  if (member.role == 'captain')
                    PopupMenuItem(
                      value: 'member',
                      child: Text('Hacer miembro',
                          style: TextStyle(color: AppColors.textPrimary)),
                    ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Quitar del equipo',
                        style: TextStyle(color: AppColors.notificationDot)),
                  ),
                ],
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _RequestsSection extends ConsumerWidget {
  const _RequestsSection({
    required this.teamId,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final String teamId;
  final bool busy;
  final ValueChanged<TeamMember> onAccept;
  final ValueChanged<TeamMember> onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(teamRequestsProvider(teamId));
    return requestsAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return const TeamInfoCard(
            icon: Icons.inbox_outlined,
            text: 'No hay solicitudes pendientes.',
          );
        }
        return Column(
          children: [
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _RequestTile(
                member: list[i],
                busy: busy,
                onAccept: () => onAccept(list[i]),
                onReject: () => onReject(list[i]),
              ),
            ],
          ],
        );
      },
      loading: () => const TeamLoadingCard(),
      error: (err, _) => TeamInlineErrorCard(
        error: err,
        onRetry: () => ref.invalidate(teamRequestsProvider(teamId)),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.member,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final TeamMember member;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final c = member.user;
    final subtitle = _subtitle(c);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            TeamMemberAvatar(url: c.avatar, initial: c.initial, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.displayName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Rechazar',
              onPressed: busy ? null : onReject,
              icon: Icon(Icons.close, color: AppColors.notificationDot),
            ),
            IconButton(
              tooltip: 'Aceptar',
              onPressed: busy ? null : onAccept,
              icon: Icon(Icons.check, color: AppColors.brandGreen),
            ),
          ],
        ),
      ),
    );
  }
}

String? _subtitle(Contact c) {
  if (c.alias != null && c.alias!.trim().isNotEmpty) return '@${c.alias!.trim()}';
  if (c.email != null && c.email!.trim().isNotEmpty) return c.email!.trim();
  if (c.stringId != null && c.stringId!.trim().isNotEmpty) return c.stringId!.trim();
  return null;
}

// ---------------------------------------------------------------------------
// Agregar miembro
// ---------------------------------------------------------------------------

class _AddTeamMemberSheet extends ConsumerStatefulWidget {
  const _AddTeamMemberSheet({
    required this.teamId,
    required this.existingUserIds,
  });

  final String teamId;
  final Set<String> existingUserIds;

  @override
  ConsumerState<_AddTeamMemberSheet> createState() =>
      _AddTeamMemberSheetState();
}

class _AddTeamMemberSheetState extends ConsumerState<_AddTeamMemberSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  Contact? _selected;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Id de **usuario** del contacto, si ya lo conocemos. Los contactos vienen de
  /// `GET /profiles/contacts`, donde el objeto raíz es el *perfil* (`id` =
  /// profileId) y el id de usuario va anidado en `user.id` (`Contact.userId`).
  /// Si el backend no lo incluyó, devuelve `null` y se resuelve al enviar.
  static String? _knownUserId(Contact c) {
    final userId = c.userId?.trim();
    return (userId != null && userId.isNotEmpty) ? userId : null;
  }

  bool _matches(Contact c) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return c.displayName.toLowerCase().contains(q) ||
        (c.alias?.toLowerCase().contains(q) ?? false) ||
        (c.email?.toLowerCase().contains(q) ?? false) ||
        (c.stringId?.toLowerCase().contains(q) ?? false);
  }

  /// Resuelve el `userId` real del contacto. Si ya lo trae, lo usa; si no, lo
  /// busca por `stringId`/`alias` con `GET /profiles/search` (esa respuesta sí
  /// incluye `user.id`). Nunca devuelve el `profileId`.
  Future<String?> _resolveUserId(Contact c) async {
    final known = _knownUserId(c);
    if (known != null) return known;
    final query = (c.stringId != null && c.stringId!.trim().isNotEmpty)
        ? c.stringId!.trim()
        : (c.alias != null && c.alias!.trim().isNotEmpty)
            ? c.alias!.trim()
            : null;
    if (query == null) return null;
    final results = await ref.read(contactsApiProvider).searchProfiles(query);
    for (final r in results) {
      final rid = _knownUserId(r);
      if (rid != null) return rid;
    }
    return null;
  }

  Future<void> _submit() async {
    final selected = _selected;
    if (selected == null) {
      setState(() => _error = 'Selecciona un contacto');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final targetUserId = await _resolveUserId(selected);
      if (targetUserId == null) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = 'No pudimos identificar al usuario de este contacto';
        });
        return;
      }
      await ref
          .read(teamsApiProvider)
          .addMember(widget.teamId, userId: targetUserId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = teamErrorMessage(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No pudimos agregar al miembro';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final contactsAsync = ref.watch(myContactsProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
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
            Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Agregar miembro',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TeamSearchField(
                controller: _searchController,
                hint: 'Buscar contacto...',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Flexible(
              child: contactsAsync.when(
                data: (all) {
                  if (all.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: TeamInfoCard(
                        icon: Icons.group_outlined,
                        text: 'No tienes contactos para agregar.',
                      ),
                    );
                  }
                  final candidates = all.where((c) {
                    final uid = _knownUserId(c);
                    if (uid != null && widget.existingUserIds.contains(uid)) {
                      return false;
                    }
                    return _matches(c);
                  }).toList(growable: false);
                  if (candidates.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: TeamInfoCard(
                        icon: Icons.search_off,
                        text: _query.trim().isEmpty
                            ? 'No hay contactos disponibles para agregar.'
                            : 'Sin contactos para "${_query.trim()}".',
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    itemCount: candidates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = candidates[i];
                      final isSelected = _selected != null &&
                          (identical(_selected, c) ||
                              (_selected!.id.isNotEmpty &&
                                  _selected!.id == c.id));
                      return _ContactPickRow(
                        contact: c,
                        selected: isSelected,
                        onTap: () => setState(() => _selected = c),
                      );
                    },
                  );
                },
                loading: () => Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.brandGreen),
                  ),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: TeamInlineErrorCard(
                    error: err,
                    onRetry: () => ref.invalidate(myContactsProvider),
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(
                  _error!,
                  style: TextStyle(
                      color: AppColors.notificationDot, fontSize: 13),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + media.padding.bottom),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        AppColors.brandGreen.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: (_saving || _selected == null) ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Agregar',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactPickRow extends StatelessWidget {
  const _ContactPickRow({
    required this.contact,
    required this.selected,
    required this.onTap,
  });

  final Contact contact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle(contact);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.brandGreen : AppColors.borderSubtle,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              TeamMemberAvatar(url: contact.avatar, initial: contact.initial),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppColors.brandGreen : AppColors.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
