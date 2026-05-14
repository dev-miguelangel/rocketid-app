import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../teams/domain/team.dart';
import '../teams/presentation/team_form_sheet.dart';
import '../teams/presentation/teams_tab.dart';
import 'domain/contact.dart';
import 'domain/contact_group.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.index != _tabIndex) {
      setState(() => _tabIndex = _tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openAddContactSheet() async {
    final messenger = ScaffoldMessenger.of(context);
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddContactSheet(),
    );
    if (!mounted) return;
    if (added == true) {
      ref.invalidate(myContactsProvider);
      ref.invalidate(contactSuggestionsProvider);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Contacto agregado'),
            backgroundColor: AppColors.surfaceCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _openCreateGroupSheet() async {
    final messenger = ScaffoldMessenger.of(context);
    final created = await showModalBottomSheet<ContactGroup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateGroupSheet(),
    );
    if (!mounted) return;
    if (created != null) {
      ref.invalidate(contactGroupsProvider);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Grupo "${created.name}" creado'),
            backgroundColor: AppColors.surfaceCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _openCreateTeamSheet() async {
    final messenger = ScaffoldMessenger.of(context);
    final created = await showModalBottomSheet<Team>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TeamFormSheet(),
    );
    if (!mounted) return;
    if (created != null) {
      ref.invalidate(myTeamsProvider);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Equipo "${created.name}" creado'),
            backgroundColor: AppColors.surfaceCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Widget? _buildFab() {
    switch (_tabIndex) {
      case 0:
        return FloatingActionButton.extended(
          key: const ValueKey('fab-add-contact'),
          onPressed: _openAddContactSheet,
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text(
            'Agregar',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      case 1:
        return FloatingActionButton.extended(
          key: const ValueKey('fab-create-group'),
          onPressed: _openCreateGroupSheet,
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.group_add_outlined),
          label: const Text(
            'Crear grupo',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      case 2:
        return FloatingActionButton.extended(
          key: const ValueKey('fab-create-team'),
          onPressed: _openCreateTeamSheet,
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: const Text(
            'Crear equipo',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppTopBar.inner(title: 'Contactos'),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) => _onBottomNavTap(context, i),
      ),
      floatingActionButton: _buildFab(),
      body: Column(
        children: [
          _TabsHeader(controller: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ContactsTabView(),
                _GroupsTabView(),
                TeamsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTap(BuildContext context, int i) {
    if (i == 3) return;
    if (i == 0) {
      context.go('/inicio');
      return;
    }
    if (i == 4) {
      context.go('/perfil');
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Esta sección estará disponible pronto'),
          backgroundColor: AppColors.surfaceCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _TabsHeader extends StatelessWidget {
  const _TabsHeader({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBg,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.brandGreen,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.brandGreen,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Contactos'),
          Tab(text: 'Grupos'),
          Tab(text: 'Equipos'),
        ],
      ),
    );
  }
}

class _ContactsTabView extends ConsumerStatefulWidget {
  const _ContactsTabView();

  @override
  ConsumerState<_ContactsTabView> createState() => _ContactsTabViewState();
}

/// Mínimo de caracteres para disparar la búsqueda de personas en el backend.
const int _kSearchMinChars = 3;

class _ContactsTabViewState extends ConsumerState<_ContactsTabView> {
  final _searchController = TextEditingController();
  String _query = '';
  String _searchTerm = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final term = value.trim();
      final next = term.length >= _kSearchMinChars ? term : '';
      if (next != _searchTerm) setState(() => _searchTerm = next);
    });
  }

  bool get _isSearching => _searchTerm.length >= _kSearchMinChars;

  String get _searchKey => _searchTerm.toLowerCase();

  bool _matches(Contact c) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final fields = <String?>[
      c.displayName,
      c.email,
      c.stringId,
      c.alias,
      c.city,
    ];
    for (final f in fields) {
      if (f != null && f.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  void _refreshAll() {
    ref.invalidate(myContactsProvider);
    ref.invalidate(contactSuggestionsProvider);
    if (_isSearching) ref.invalidate(profileSearchProvider(_searchKey));
  }

  void _showSoon(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label estará disponible pronto'),
          backgroundColor: AppColors.surfaceCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final myContacts = ref.watch(myContactsProvider);
    final searching = _isSearching;
    final AsyncValue<List<Contact>> suggestions = searching
        ? ref.watch(profileSearchProvider(_searchKey))
        : ref.watch(contactSuggestionsProvider);
    final partialQuery = !searching &&
        _query.trim().isNotEmpty &&
        _query.trim().length < _kSearchMinChars;

    return RefreshIndicator(
      color: AppColors.brandGreen,
      backgroundColor: AppColors.surfaceCard,
      onRefresh: () async {
        _refreshAll();
        await Future.wait<void>([
          ref.read(myContactsProvider.future),
          if (searching)
            ref.read(profileSearchProvider(_searchKey).future)
          else
            ref.read(contactSuggestionsProvider.future),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _SearchField(
            controller: _searchController,
            onChanged: _onQueryChanged,
          ),
          const SizedBox(height: 16),
          _InviteCard(onTap: () => _showSoon('Compartir por WhatsApp')),
          const SizedBox(height: 24),
          const _SectionLabel('MIS CONTACTOS'),
          const SizedBox(height: 10),
          _ContactsBlock(
            value: myContacts,
            filter: _matches,
            empty: const _EmptyCard(
              icon: Icons.groups_outlined,
              title: 'Sin contactos aún',
              subtitle:
                  'Busca personas por alias, correo o ID para agregarlas.',
            ),
            tile: (c) => _ContactTile(
              contact: c,
              kind: _TileKind.myContact,
              onChanged: _refreshAll,
            ),
            onRetry: () => ref.invalidate(myContactsProvider),
            noResults: 'Sin resultados en tus contactos.',
          ),
          const SizedBox(height: 24),
          _SectionLabel(searching ? 'RESULTADOS' : 'SUGERENCIAS'),
          const SizedBox(height: 10),
          if (partialQuery)
            const _InfoCard(
              icon: Icons.search,
              text: 'Escribe al menos 3 caracteres para buscar personas.',
            )
          else
            _ContactsBlock(
              value: suggestions,
              filter: searching ? (Contact _) => true : _matches,
              empty: searching
                  ? _InfoCard(
                      icon: Icons.search_off,
                      text: 'Sin personas para "$_searchTerm".',
                    )
                  : const _EmptyCard(
                      icon: Icons.person_search_outlined,
                      title: 'No hay sugerencias por ahora',
                      subtitle:
                          'Vuelve más tarde para descubrir nuevas personas.',
                    ),
              tile: (c) => _ContactTile(
                contact: c,
                kind: _TileKind.suggestion,
                onChanged: _refreshAll,
              ),
              onRetry: () {
                if (searching) {
                  ref.invalidate(profileSearchProvider(_searchKey));
                } else {
                  ref.invalidate(contactSuggestionsProvider);
                }
              },
              noResults: 'Sin sugerencias para esa búsqueda.',
            ),
        ],
      ),
    );
  }
}

class _ContactsBlock extends StatelessWidget {
  const _ContactsBlock({
    required this.value,
    required this.filter,
    required this.empty,
    required this.tile,
    required this.onRetry,
    required this.noResults,
  });

  final AsyncValue<List<Contact>> value;
  final bool Function(Contact) filter;
  final Widget empty;
  final Widget Function(Contact) tile;
  final VoidCallback onRetry;
  final String noResults;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (list) {
        if (list.isEmpty) return empty;
        final filtered = list.where(filter).toList(growable: false);
        if (filtered.isEmpty) {
          return _InfoCard(icon: Icons.search_off, text: noResults);
        }
        return Column(
          children: [
            for (var i = 0; i < filtered.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              tile(filtered[i]),
            ],
          ],
        );
      },
      loading: () => const _LoadingCard(),
      error: (err, _) => _InlineErrorCard(error: err, onRetry: onRetry),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    this.hint = 'Alias, correo o ID...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 15),
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.brandGreen),
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x1F34D399),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x6634D399)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chat, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invitar a unirse',
                      style: TextStyle(
                        color: AppColors.brandGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Comparte RocketId por WhatsApp',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textFaint),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: AppColors.brandGreen,
          ),
        ),
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.error_outline,
                color: AppColors.notificationDot,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No pudimos cargar esta sección',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _friendlyError(error),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRetry,
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  color: AppColors.brandGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _TileKind { myContact, suggestion }

class _ContactTile extends ConsumerStatefulWidget {
  const _ContactTile({
    required this.contact,
    required this.kind,
    required this.onChanged,
  });

  final Contact contact;
  final _TileKind kind;
  final VoidCallback onChanged;

  @override
  ConsumerState<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends ConsumerState<_ContactTile> {
  bool _saving = false;

  Future<void> _add() async {
    final stringId = widget.contact.stringId;
    if (stringId == null || stringId.isEmpty) {
      _toast('Este contacto no tiene un ID disponible');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(contactsApiProvider).addContact(stringId);
      if (!mounted) return;
      widget.onChanged();
      _toast('Contacto agregado');
    } on DioException catch (e) {
      _toast(_dioMessage(e));
    } catch (_) {
      _toast('No pudimos agregar el contacto');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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

  void _openProfile() => _showContactProfileSheet(context, widget.contact);

  @override
  Widget build(BuildContext context) {
    final c = widget.contact;
    final subtitle = _contactSubtitle(c);
    final isSuggestion = widget.kind == _TileKind.suggestion;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openProfile,
            child: _ContactAvatar(url: c.avatar, initial: c.initial),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.displayName,
                  style: const TextStyle(
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
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (isSuggestion) ...[
            const SizedBox(width: 8),
            _IconSquareButton(
              icon: Icons.person_outline,
              onTap: _openProfile,
            ),
            const SizedBox(width: 8),
            _AddButton(saving: _saving, onPressed: _saving ? null : _add),
          ],
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: isSuggestion
          ? content
          : Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: _openProfile, child: content),
            ),
    );
  }

}

String? _contactSubtitle(Contact c) {
  final alias = c.alias;
  final stringId = c.stringId;
  final city = c.city;
  final parts = <String>[
    if (alias != null && alias.isNotEmpty) '@$alias',
    if (stringId != null && stringId.isNotEmpty) stringId,
    if (city != null && city.isNotEmpty) city,
  ];
  if (parts.isEmpty) return c.email;
  return parts.join(' · ');
}

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({required this.url, required this.initial});

  final String? url;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.brandGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.isNotEmpty
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initialChild(),
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : _initialChild(),
            )
          : _initialChild(),
    );
  }

  Widget _initialChild() => Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _IconSquareButton extends StatelessWidget {
  const _IconSquareButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: AppColors.surfaceChip,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderChip),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.saving, required this.onPressed});

  final bool saving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.black,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_alt_1, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Agregar',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contact profile sheet
// ---------------------------------------------------------------------------

Future<void> _showContactProfileSheet(BuildContext context, Contact contact) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ContactProfileSheet(contact: contact),
  );
}

class _ContactProfileSheet extends StatefulWidget {
  const _ContactProfileSheet({required this.contact});

  final Contact contact;

  @override
  State<_ContactProfileSheet> createState() => _ContactProfileSheetState();
}

class _ContactProfileSheetState extends State<_ContactProfileSheet> {
  bool _showEmergency = false;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final c = widget.contact;
    final email = c.email;
    final stringId = c.stringId;

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
            child: Row(
              children: [
                const Text(
                  'Perfil',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.borderSubtle,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 28 + media.padding.bottom),
              child: Column(
                children: [
                  _BigAvatar(url: c.avatar, initial: c.initial),
                  const SizedBox(height: 18),
                  Text(
                    c.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (stringId != null && stringId.isNotEmpty) ...[
                    _IdPill(stringId: stringId),
                    const SizedBox(height: 16),
                  ],
                  _EmergencyButton(
                    expanded: _showEmergency,
                    onPressed: () =>
                        setState(() => _showEmergency = !_showEmergency),
                  ),
                  if (_showEmergency) ...[
                    const SizedBox(height: 12),
                    _EmergencyPanel(contact: c),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigAvatar extends StatelessWidget {
  const _BigAvatar({required this.url, required this.initial});

  final String? url;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.brandGreen,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderChip, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.isNotEmpty
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initialChild(),
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : _initialChild(),
            )
          : _initialChild(),
    );
  }

  Widget _initialChild() => Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _IdPill extends StatefulWidget {
  const _IdPill({required this.stringId});

  final String stringId;

  @override
  State<_IdPill> createState() => _IdPillState();
}

class _IdPillState extends State<_IdPill> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.stringId));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceChip,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderChip),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _copy,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _copied ? Icons.check : Icons.badge_outlined,
                size: 18,
                color: AppColors.brandGreen,
              ),
              const SizedBox(width: 10),
              Text(
                _copied ? 'Copiado' : widget.stringId,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.expanded, required this.onPressed});

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.borderChip),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emergency,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            const Text(
              'Ver datos de emergencia',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyPanel extends StatelessWidget {
  const _EmergencyPanel({required this.contact});

  final Contact contact;

  static bool _hasText(String? v) => v != null && v.trim().isNotEmpty;
  static bool _hasList(List<String>? v) =>
      v != null && v.any((e) => e.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final ecName = contact.emergencyContactName;
    final ecPhone = contact.emergencyContactPhone;
    final ecRel = contact.emergencyContactRelationship;
    final hasEmergency = _hasText(ecName) || _hasText(ecPhone) || _hasText(ecRel);

    final bloodType = contact.bloodType;
    final allergies = contact.allergies;
    final conditions = contact.conditions;
    final medications = contact.medications;
    final hasMedical = _hasText(bloodType) ||
        _hasList(allergies) ||
        _hasText(conditions) ||
        _hasList(medications);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
              SizedBox(width: 8),
              Text(
                'Datos de emergencia',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasEmergency) ...[
            const _SectionLabel('CONTACTO DE EMERGENCIA'),
            const SizedBox(height: 6),
            if (_hasText(ecName))
              _InfoRow(icon: Icons.person_outline, text: ecName!),
            if (_hasText(ecPhone))
              _InfoRow(icon: Icons.phone_outlined, text: ecPhone!),
            if (_hasText(ecRel))
              _InfoRow(icon: Icons.favorite_border, text: ecRel!),
            if (_hasText(ecPhone)) ...[
              const SizedBox(height: 12),
              _EmergencyActions(phone: ecPhone!),
            ],
          ],
          if (hasEmergency && hasMedical) const SizedBox(height: 14),
          if (hasMedical) ...[
            const _SectionLabel('INFORMACIÓN MÉDICA'),
            const SizedBox(height: 6),
            if (_hasText(bloodType))
              _InfoRow(
                icon: Icons.bloodtype_outlined,
                label: 'Tipo de sangre',
                text: bloodType!,
              ),
            if (_hasList(allergies))
              _InfoRow(
                icon: Icons.warning_amber_outlined,
                label: 'Alergias',
                text: allergies!.join(', '),
              ),
            if (_hasText(conditions))
              _InfoRow(
                icon: Icons.healing_outlined,
                label: 'Condiciones',
                text: conditions!,
              ),
            if (_hasList(medications))
              _InfoRow(
                icon: Icons.medication_outlined,
                label: 'Medicamentos',
                text: medications!.join(', '),
              ),
          ],
          if (!hasEmergency && !hasMedical)
            const Text(
              'Este contacto aún no comparte sus datos de emergencia ni su información médica.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _EmergencyActions extends StatelessWidget {
  const _EmergencyActions({required this.phone});

  final String phone;

  static String _digitsOnly(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _open(BuildContext context, Uri uri, String fallbackMsg) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && messenger != null) {
      messenger.showSnackBar(SnackBar(content: Text(fallbackMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final waNumber = _digitsOnly(phone);
    final canWhatsapp = waNumber.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('WhatsApp'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandGreen,
              side: const BorderSide(color: AppColors.brandGreen),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: !canWhatsapp
                ? null
                : () => _open(
                      context,
                      Uri.parse('https://wa.me/$waNumber'),
                      'No se pudo abrir WhatsApp',
                    ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.call_outlined, size: 18),
            label: const Text('Llamar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.borderChip),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _open(
              context,
              Uri(scheme: 'tel', path: phone.replaceAll(' ', '')),
              'No se pudo iniciar la llamada',
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.label});

  final IconData icon;
  final String text;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.3,
                ),
                children: [
                  if (label != null)
                    TextSpan(
                      text: '$label: ',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add contact sheet
// ---------------------------------------------------------------------------

class _AddContactSheet extends ConsumerStatefulWidget {
  const _AddContactSheet();

  @override
  ConsumerState<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends ConsumerState<_AddContactSheet> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorText = 'Ingresa un ID');
      return;
    }
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      await ref.read(contactsApiProvider).addContact(value);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = _dioMessage(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = 'No pudimos agregar el contacto';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            const Text(
              'Agregar contacto',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Escribe el ID público de la persona que quieres agregar.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_saving,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                LengthLimitingTextInputFormatter(40),
              ],
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ej: ABC123',
                hintStyle: const TextStyle(color: AppColors.textFaint),
                filled: true,
                fillColor: AppColors.surfaceChip,
                errorText: _errorText,
                prefixIcon: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.textMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderChip),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.brandGreen),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Agregar contacto',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
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

String _dioMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final msg = data['message'] ?? data['error'];
    if (msg is String && msg.isNotEmpty) return msg;
  }
  final status = e.response?.statusCode;
  if (status == 404) return 'No encontramos ese contacto';
  if (status == 409) return 'Ya tienes este contacto';
  if (status != null) return 'Error $status al agregar contacto';
  return 'No pudimos agregar el contacto';
}

// ---------------------------------------------------------------------------
// Groups tab
// ---------------------------------------------------------------------------

class _GroupsTabView extends ConsumerStatefulWidget {
  const _GroupsTabView();

  @override
  ConsumerState<_GroupsTabView> createState() => _GroupsTabViewState();
}

class _GroupsTabViewState extends ConsumerState<_GroupsTabView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(ContactGroup g) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty || g.name.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(contactGroupsProvider);

    return RefreshIndicator(
      color: AppColors.brandGreen,
      backgroundColor: AppColors.surfaceCard,
      onRefresh: () async {
        ref.invalidate(contactGroupsProvider);
        await ref.read(contactGroupsProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _SearchField(
            controller: _searchController,
            hint: 'Buscar grupo...',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('MIS GRUPOS'),
          const SizedBox(height: 10),
          groups.when(
            data: (list) {
              if (list.isEmpty) {
                return const _EmptyCard(
                  icon: Icons.workspaces_outline,
                  title: 'Sin grupos aún',
                  subtitle: 'Crea un grupo para organizar a tus contactos.',
                );
              }
              final filtered = list.where(_matches).toList(growable: false);
              if (filtered.isEmpty) {
                return const _InfoCard(
                  icon: Icons.search_off,
                  text: 'Sin grupos para esa búsqueda.',
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < filtered.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _GroupTile(group: filtered[i]),
                  ],
                ],
              );
            },
            loading: () => const _LoadingCard(),
            error: (err, _) => _InlineErrorCard(
              error: err,
              onRetry: () => ref.invalidate(contactGroupsProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group});

  final ContactGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () async {
            final result = await _showGroupDetailSheet(context, group);
            if (result == 'deleted' && context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Grupo "${group.name}" eliminado'),
                    backgroundColor: AppColors.surfaceCard,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceChip,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderChip),
                  ),
                  child: const Icon(
                    Icons.workspaces_outline,
                    color: AppColors.brandGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _membersLabel(group.memberCount),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _membersLabel(int n) => n == 1 ? '1 contacto' : '$n contactos';

// ---------------------------------------------------------------------------
// Group detail sheet
// ---------------------------------------------------------------------------

Future<String?> _showGroupDetailSheet(BuildContext context, ContactGroup group) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _GroupDetailSheet(groupId: group.id, initialName: group.name),
  );
}

class _GroupDetailSheet extends ConsumerStatefulWidget {
  const _GroupDetailSheet({required this.groupId, required this.initialName});

  final String groupId;
  final String initialName;

  @override
  ConsumerState<_GroupDetailSheet> createState() => _GroupDetailSheetState();
}

class _GroupDetailSheetState extends ConsumerState<_GroupDetailSheet> {
  bool _busy = false;

  String get _groupId => widget.groupId;

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

  Future<void> _rename(String currentName) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _GroupNameDialog(
        title: 'Renombrar grupo',
        initialValue: currentName,
        actionLabel: 'Guardar',
      ),
    );
    if (newName == null || newName == currentName) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(groupsApiProvider).rename(_groupId, newName);
      if (!mounted) return;
      ref.invalidate(groupDetailProvider(_groupId));
      ref.invalidate(contactGroupsProvider);
      _toast('Grupo actualizado');
    } on DioException catch (e) {
      _toast(_groupErrorMessage(e));
    } catch (_) {
      _toast('No pudimos actualizar el grupo');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text(
          'Eliminar grupo',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: AppColors.notificationDot,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(groupsApiProvider).delete(_groupId);
      if (!mounted) return;
      ref.invalidate(contactGroupsProvider);
      Navigator.of(context).pop('deleted');
    } on DioException catch (e) {
      _toast(_groupErrorMessage(e));
      if (mounted) setState(() => _busy = false);
    } catch (_) {
      _toast('No pudimos eliminar el grupo');
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addMembers(ContactGroup group) async {
    final existing = group.contacts.map((c) => c.id).toSet();
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddGroupMembersSheet(
        groupId: _groupId,
        existingContactIds: existing,
      ),
    );
    if (!mounted) return;
    if (added == true) {
      ref.invalidate(groupDetailProvider(_groupId));
      ref.invalidate(contactGroupsProvider);
      _toast('Contactos agregados al grupo');
    }
  }

  Future<void> _removeMember(Contact c) async {
    setState(() => _busy = true);
    try {
      await ref.read(groupsApiProvider).removeContacts(_groupId, [c.id]);
      if (!mounted) return;
      ref.invalidate(groupDetailProvider(_groupId));
      ref.invalidate(contactGroupsProvider);
      _toast('${c.displayName} se quitó del grupo');
    } on DioException catch (e) {
      _toast(_groupErrorMessage(e));
    } catch (_) {
      _toast('No pudimos quitar el contacto');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final detailAsync = ref.watch(groupDetailProvider(_groupId));
    final name = detailAsync.maybeWhen(
      data: (g) => g.name,
      orElse: () => widget.initialName,
    );

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
      decoration: const BoxDecoration(
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
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceChip,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.borderChip),
                  ),
                  child: const Icon(
                    Icons.workspaces_outline,
                    color: AppColors.brandGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Renombrar',
                  onPressed: _busy ? null : () => _rename(name),
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.textMuted),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.borderSubtle),
          Flexible(
            child: detailAsync.when(
              data: (g) => _buildBody(g, media.padding.bottom),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 56),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.brandGreen),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.notificationDot, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'No pudimos cargar el grupo',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _friendlyError(err),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () =>
                          ref.invalidate(groupDetailProvider(_groupId)),
                      child: const Text(
                        'Reintentar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ContactGroup g, double bottomInset) {
    final members = g.contacts;
    final children = <Widget>[
      Text(
        _membersLabel(g.memberCount),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brandGreen,
            side: const BorderSide(color: AppColors.borderChip),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _busy ? null : () => _addMembers(g),
          icon: const Icon(Icons.person_add_alt_1, size: 18),
          label: const Text(
            'Agregar contactos',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      const SizedBox(height: 16),
    ];

    if (members.isEmpty) {
      children.add(const _EmptyCard(
        icon: Icons.group_outlined,
        title: 'Grupo vacío',
        subtitle: 'Agrega contactos para empezar a usar este grupo.',
      ));
    } else {
      for (var i = 0; i < members.length; i++) {
        if (i > 0) children.add(const SizedBox(height: 10));
        children.add(_GroupMemberTile(
          contact: members[i],
          onRemove: _busy ? null : () => _removeMember(members[i]),
        ));
      }
    }

    children
      ..add(const SizedBox(height: 24))
      ..add(SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.notificationDot,
            side: const BorderSide(color: AppColors.borderChip),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _busy ? null : _delete,
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text(
            'Eliminar grupo',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ));

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
      children: children,
    );
  }
}

class _GroupMemberTile extends StatelessWidget {
  const _GroupMemberTile({required this.contact, required this.onRemove});

  final Contact contact;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = contact;
    final subtitle = _contactSubtitle(c);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => _showContactProfileSheet(context, c),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                _ContactAvatar(url: c.avatar, initial: c.initial),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.displayName,
                        style: const TextStyle(
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
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  tooltip: 'Quitar del grupo',
                  icon: const Icon(Icons.close, size: 18,
                      color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create group sheet
// ---------------------------------------------------------------------------

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet();

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorText = 'Ingresa un nombre');
      return;
    }
    if (!RegExp(r'^[a-z0-9]+$').hasMatch(value)) {
      setState(() => _errorText = 'Solo minúsculas y números, sin espacios');
      return;
    }
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      final group = await ref.read(groupsApiProvider).create(value);
      if (!mounted) return;
      Navigator.of(context).pop(group);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = _groupErrorMessage(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = 'No pudimos crear el grupo';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            const Text(
              'Crear grupo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Solo minúsculas y números (sin espacios), máximo 30 caracteres.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_saving,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              inputFormatters: [
                const _LowercaseFormatter(),
                FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9]')),
                LengthLimitingTextInputFormatter(30),
              ],
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ej: trabajo2026',
                hintStyle: const TextStyle(color: AppColors.textFaint),
                filled: true,
                fillColor: AppColors.surfaceChip,
                errorText: _errorText,
                prefixIcon: const Icon(
                  Icons.workspaces_outline,
                  color: AppColors.textMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderChip),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.brandGreen),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Crear grupo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
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

// ---------------------------------------------------------------------------
// Add members to group sheet
// ---------------------------------------------------------------------------

class _AddGroupMembersSheet extends ConsumerStatefulWidget {
  const _AddGroupMembersSheet({
    required this.groupId,
    required this.existingContactIds,
  });

  final String groupId;
  final Set<String> existingContactIds;

  @override
  ConsumerState<_AddGroupMembersSheet> createState() =>
      _AddGroupMembersSheetState();
}

class _AddGroupMembersSheetState extends ConsumerState<_AddGroupMembersSheet> {
  final Set<String> _selected = {};
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (_selected.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(groupsApiProvider)
          .addContacts(widget.groupId, _selected.toList());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _groupErrorMessage(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No pudimos agregar los contactos';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final myContacts = ref.watch(myContactsProvider);

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Agregar contactos',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.borderSubtle),
          Flexible(
            child: myContacts.when(
              data: (all) {
                final available = all
                    .where((c) => !widget.existingContactIds.contains(c.id))
                    .toList(growable: false);
                if (available.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No tienes contactos disponibles para agregar a este grupo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: available.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final c = available[i];
                    return _SelectableContactRow(
                      contact: c,
                      selected: _selected.contains(c.id),
                      onChanged: (v) => setState(() {
                        if (v) {
                          _selected.add(c.id);
                        } else {
                          _selected.remove(c.id);
                        }
                      }),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.brandGreen),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No pudimos cargar tus contactos.\n${_friendlyError(err)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.notificationDot,
                  fontSize: 13,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + media.padding.bottom),
            child: SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed:
                    (_selected.isEmpty || _saving) ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        _selected.isEmpty
                            ? 'Selecciona contactos'
                            : 'Agregar (${_selected.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableContactRow extends StatelessWidget {
  const _SelectableContactRow({
    required this.contact,
    required this.selected,
    required this.onChanged,
  });

  final Contact contact;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = contact;
    final subtitle = _contactSubtitle(c);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => onChanged(!selected),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0x1434D399) : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.brandGreen : AppColors.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              _ContactAvatar(url: c.avatar, initial: c.initial),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.displayName,
                      style: const TextStyle(
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
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Checkbox(
                value: selected,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.brandGreen,
                checkColor: Colors.black,
                side: const BorderSide(color: AppColors.borderChip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group name dialog (create / rename)
// ---------------------------------------------------------------------------

class _GroupNameDialog extends StatefulWidget {
  const _GroupNameDialog({
    required this.title,
    required this.initialValue,
    required this.actionLabel,
  });

  final String title;
  final String initialValue;
  final String actionLabel;

  @override
  State<_GroupNameDialog> createState() => _GroupNameDialogState();
}

class _GroupNameDialogState extends State<_GroupNameDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _controller.text.trim();
    if (v.isEmpty) {
      setState(() => _error = 'Ingresa un nombre');
      return;
    }
    if (!RegExp(r'^[a-z0-9]+$').hasMatch(v)) {
      setState(() => _error = 'Solo minúsculas y números, sin espacios');
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      title: Text(
        widget.title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        inputFormatters: [
          const _LowercaseFormatter(),
          FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9]')),
          LengthLimitingTextInputFormatter(30),
        ],
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'nombre del grupo',
          hintStyle: const TextStyle(color: AppColors.textFaint),
          errorText: _error,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.borderChip),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.brandGreen),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
            foregroundColor: Colors.black,
          ),
          onPressed: _submit,
          child: Text(
            widget.actionLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _LowercaseFormatter extends TextInputFormatter {
  const _LowercaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lowered = newValue.text.toLowerCase();
    if (lowered == newValue.text) return newValue;
    return newValue.copyWith(text: lowered);
  }
}

String _friendlyError(Object error) {
  if (error is! DioException) {
    final text = error.toString();
    return text.length > 160 ? '${text.substring(0, 157)}…' : text;
  }
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final msg = data['message'] ?? data['error'];
    if (msg is String && msg.isNotEmpty) return msg;
    if (msg is List && msg.isNotEmpty) return msg.first.toString();
  }
  final status = error.response?.statusCode;
  if (status == 500) return 'El servidor tuvo un error (500). Intenta más tarde.';
  if (status == 404) return 'No encontrado (404).';
  if (status == 401 || status == 403) return 'No tienes acceso a esta sección.';
  if (status != null) return 'Error del servidor ($status).';
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'La conexión tardó demasiado. Revisa tu internet.';
    case DioExceptionType.connectionError:
      return 'No pudimos conectar con el servidor.';
    default:
      return 'No pudimos completar la solicitud.';
  }
}

String _groupErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final msg = data['message'] ?? data['error'];
    if (msg is String && msg.isNotEmpty) return msg;
    if (msg is List && msg.isNotEmpty) return msg.first.toString();
  }
  final status = e.response?.statusCode;
  if (status == 409) return 'Ya tienes un grupo con ese nombre';
  if (status == 404) return 'No encontramos el grupo';
  if (status == 400) return 'El nombre no es válido';
  if (status != null) return 'Error $status';
  return 'Algo salió mal. Intenta de nuevo.';
}
