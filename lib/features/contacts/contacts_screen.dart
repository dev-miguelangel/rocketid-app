import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_top_bar.dart';
import 'domain/contact.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppTopBar.inner(title: 'Contactos'),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) => _onBottomNavTap(context, i),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddContactSheet,
        backgroundColor: AppColors.brandGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(
          'Agregar',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          _TabsHeader(controller: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ContactsTabView(),
                _ComingSoonTab(
                  icon: Icons.groups_outlined,
                  title: 'Grupos',
                  message: 'Pronto podrás organizar tus contactos en grupos.',
                ),
                _ComingSoonTab(
                  icon: Icons.workspaces_outline,
                  title: 'Equipos',
                  message: 'Pronto podrás crear equipos y colaborar con otros.',
                ),
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

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textFaint),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactsTabView extends ConsumerStatefulWidget {
  const _ContactsTabView();

  @override
  ConsumerState<_ContactsTabView> createState() => _ContactsTabViewState();
}

class _ContactsTabViewState extends ConsumerState<_ContactsTabView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final suggestions = ref.watch(contactSuggestionsProvider);

    return RefreshIndicator(
      color: AppColors.brandGreen,
      backgroundColor: AppColors.surfaceCard,
      onRefresh: () async {
        _refreshAll();
        await Future.wait<void>([
          ref.read(myContactsProvider.future),
          ref.read(contactSuggestionsProvider.future),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _SearchField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
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
                  'Busca personas por nombre, correo o ID para agregarlas.',
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
          const _SectionLabel('SUGERENCIAS'),
          const SizedBox(height: 10),
          _ContactsBlock(
            value: suggestions,
            filter: _matches,
            empty: const _EmptyCard(
              icon: Icons.person_search_outlined,
              title: 'No hay sugerencias por ahora',
              subtitle: 'Vuelve más tarde para descubrir nuevas personas.',
            ),
            tile: (c) => _ContactTile(
              contact: c,
              kind: _TileKind.suggestion,
              onChanged: _refreshAll,
            ),
            onRetry: () => ref.invalidate(contactSuggestionsProvider),
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
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Nombre, correo o ID...',
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
            '$error',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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
    final subtitle = _subtitle(c);
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

  static String? _subtitle(Contact c) {
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

  @override
  Widget build(BuildContext context) {
    final phone = contact.phone;
    final hasPhone = phone != null && phone.isNotEmpty;

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
          const SizedBox(height: 10),
          if (hasPhone) ...[
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  phone,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(
            hasPhone
                ? 'Este contacto aún no comparte su información médica ni su contacto de emergencia.'
                : 'Este contacto aún no comparte sus datos de emergencia.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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
