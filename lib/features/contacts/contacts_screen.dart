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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openAddContactSheet() async {
    final scaffold = ScaffoldMessenger.of(context);
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
      scaffold
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
                _ContactsTab(kind: _TabKind.myContacts),
                _ContactsTab(kind: _TabKind.suggestions),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: TabBar(
          controller: controller,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: AppColors.brandGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.black,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Mis contactos'),
            Tab(text: 'Sugerencias'),
          ],
        ),
      ),
    );
  }
}

enum _TabKind { myContacts, suggestions }

class _ContactsTab extends ConsumerWidget {
  const _ContactsTab({required this.kind});

  final _TabKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncContacts = switch (kind) {
      _TabKind.myContacts => ref.watch(myContactsProvider),
      _TabKind.suggestions => ref.watch(contactSuggestionsProvider),
    };

    return asyncContacts.when(
      data: (list) => RefreshIndicator(
        color: AppColors.brandGreen,
        backgroundColor: AppColors.surfaceCard,
        onRefresh: () async {
          switch (kind) {
            case _TabKind.myContacts:
              ref.invalidate(myContactsProvider);
              await ref.read(myContactsProvider.future);
            case _TabKind.suggestions:
              ref.invalidate(contactSuggestionsProvider);
              await ref.read(contactSuggestionsProvider.future);
          }
        },
        child: list.isEmpty
            ? _EmptyState(kind: kind)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _ContactTile(
                  contact: list[index],
                  showAddButton: kind == _TabKind.suggestions,
                  onAdded: () {
                    ref.invalidate(myContactsProvider);
                    ref.invalidate(contactSuggestionsProvider);
                  },
                ),
              ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brandGreen),
      ),
      error: (err, _) => _ErrorState(
        error: err,
        onRetry: () {
          switch (kind) {
            case _TabKind.myContacts:
              ref.invalidate(myContactsProvider);
            case _TabKind.suggestions:
              ref.invalidate(contactSuggestionsProvider);
          }
        },
      ),
    );
  }
}

class _ContactTile extends ConsumerStatefulWidget {
  const _ContactTile({
    required this.contact,
    required this.showAddButton,
    required this.onAdded,
  });

  final Contact contact;
  final bool showAddButton;
  final VoidCallback onAdded;

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
      widget.onAdded();
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

  @override
  Widget build(BuildContext context) {
    final c = widget.contact;
    final subtitle = _subtitle(c);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
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
          if (widget.showAddButton) ...[
            const SizedBox(width: 8),
            _AddButton(saving: _saving, onPressed: _saving ? null : _add),
          ],
        ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.kind});

  final _TabKind kind;

  @override
  Widget build(BuildContext context) {
    final title = kind == _TabKind.myContacts
        ? 'Aún no tienes contactos'
        : 'No hay sugerencias por ahora';
    final subtitle = kind == _TabKind.myContacts
        ? 'Agrega a alguien usando su ID o desde Sugerencias.'
        : 'Vuelve más tarde para descubrir nuevos contactos.';
    final icon = kind == _TabKind.myContacts
        ? Icons.people_outline
        : Icons.person_search_outlined;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 56, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        const Icon(
          Icons.error_outline,
          color: AppColors.notificationDot,
          size: 48,
        ),
        const SizedBox(height: 16),
        const Text(
          'No pudimos cargar los contactos',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            '$error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onRetry,
            child: const Text(
              'Reintentar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

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
                  borderSide:
                      const BorderSide(color: AppColors.borderChip),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.brandGreen),
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
