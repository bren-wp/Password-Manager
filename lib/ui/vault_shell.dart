import 'dart:math';

import 'package:flutter/material.dart';
import '../core/sensitive_clipboard.dart';

import '../core/vault_item.dart';
import '../core/vault_store.dart';
import 'brand.dart';
import 'entry_editor.dart';
import 'extra_pages.dart';

const _navigation = <(String, IconData)>[
  ('Trezor', Icons.home_outlined),
  ('Sve lozinke', Icons.list_alt),
  ('Favoriti', Icons.star_outline),
  ('Kategorije', Icons.grid_view_rounded),
  ('Sigurne bilješke', Icons.description_outlined),
  ('Kartice', Icons.credit_card_outlined),
  ('Autentifikator', Icons.verified_user_outlined),
  ('Generator', Icons.casino_outlined),
  ('Sigurnost', Icons.shield_outlined),
  ('Sigurnosna kopija', Icons.cloud_upload_outlined),
  ('Koš', Icons.delete_outline),
  ('Postavke', Icons.settings_outlined),
];

class VaultShell extends StatefulWidget {
  final VaultStore store;
  final String initialPage;
  const VaultShell({super.key, required this.store,
    this.initialPage = 'Trezor'});

  @override
  State<VaultShell> createState() => _VaultShellState();
}

class _VaultShellState extends State<VaultShell> {
  late String page = widget.initialPage;
  String query = '';
  String sortMode = 'recent';
  String? selectedId;
  String? categoryFilter;
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void navigate(String next) => setState(() {
    page = next;
    categoryFilter = null;
    query = '';
    search.clear();
    selectedId = null;
  });

  void notifyUser(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> get availableCategories => <String>{
    'Osobno', 'Posao', 'Zabava', 'Financije', 'Tehnologija', 'Ostalo',
    ...widget.store.items.where((item) => item.kind == ItemKind.category)
      .map((item) => item.title),
    ...widget.store.items.where((item) => item.kind != ItemKind.category)
      .map((item) => item.category),
  }.toList();

  Future<void> edit({ItemKind kind = ItemKind.password, VaultItem? original}) async {
    // Save while the dialog is still visible. A failed encrypted write must
    // not dispose the unsaved password the user just typed.
    final item = await showDialog<VaultItem>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EntryEditor(
        kind: original?.kind ?? kind,
        original: original,
        availableCategories: availableCategories,
        onPersist: widget.store.put,
      ),
    );
    if (item == null || !mounted) return;
    setState(() => selectedId = item.id);
    notifyUser('Zapis je sigurno spremljen.');
  }

  Future<void> remove(VaultItem item) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) =>
      AlertDialog(
        title: const Text('Obrisati zapis?'),
        content: Text('Zapis „${item.title}” premjestit će se u Koš. '
          'Možete ga kasnije vratiti.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Premjesti u Koš',
              style: TextStyle(color: VColors.red))),
        ]));
    if (yes != true) return;
    try {
      await widget.store.remove(item.id);
      if (mounted) setState(() => selectedId = null);
      notifyUser('Zapis je premješten u Koš.');
    } on VaultConflictException {
      notifyUser('Trezor je izmijenjen u drugom prozoru. '
        'Ponovno ga otključajte.');
    } catch (_) { notifyUser('Brisanje nije uspjelo.'); }
  }

  Future<void> recoverItem(VaultItem item) async {
    try {
      await widget.store.restoreTrashed(item.id);
      if (mounted) setState(() => selectedId = null);
      notifyUser('Zapis je vraćen iz Koša.');
    } catch (_) {
      notifyUser('Zapis nije vraćen.');
    }
  }

  Future<void> eraseItem(VaultItem item) async {
    final approved = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trajno ukloniti zapis?'),
        content: Text('Zapis „${item.title}” više neće biti dostupan u '
          'aktivnom trezoru. Starije šifrirane kopije mogu još '
          'sadržavati ovaj zapis.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Trajno ukloni',
              style: TextStyle(color: VColors.red))),
        ]));
    if (approved != true) return;
    try {
      await widget.store.permanentlyRemove(item.id);
      if (mounted) setState(() => selectedId = null);
      notifyUser('Zapis je uklonjen iz aktivnog trezora.');
    } catch (_) {
      notifyUser('Trajno brisanje nije uspjelo.');
    }
  }

  Future<void> copySecret(String text) async {
    if (text.isEmpty || !widget.store.isUnlocked) return;
    try {
      await SensitiveClipboard.copy(text);
      if (mounted && widget.store.isUnlocked) {
        notifyUser('Kopirano. Međuspremnik se čisti nakon 30 sekundi.');
      }
    } catch (_) {
      notifyUser('Međuspremnik nije dostupan. Pokušajte ponovno.');
    }
  }

  List<VaultItem> filtered({ItemKind? kind,
      bool favorites = false, bool trash = false}) {
    final q = query.toLowerCase().trim();
    return widget.store.items.where((item) =>
        item.kind != ItemKind.category && item.trashed == trash &&
        (kind == null || item.kind == kind) &&
        (!favorites || item.favorite) &&
        (categoryFilter == null || item.category == categoryFilter) &&
        (q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.username.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q))).toList()
      ..sort((a, b) => switch (sortMode) {
        'name' => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        'oldest' => a.updatedAt.compareTo(b.updatedAt),
        _ => b.updatedAt.compareTo(a.updatedAt),
      });
  }

  Widget sortMenu({bool compact = false}) => PopupMenuButton<String>(
    key: ValueKey(compact ? 'veldigo-search-sort' : 'veldigo-list-sort'),
    tooltip: compact ? 'Filtriraj i poredaj zapise' : 'Poredaj zapise',
    icon: Icon(compact ? Icons.tune_rounded : Icons.keyboard_arrow_down,
      size: compact ? 22 : 18, color: VColors.muted),
    onSelected: (value) => setState(() => sortMode = value),
    itemBuilder: (context) => [
      CheckedPopupMenuItem(
        value: 'recent', checked: sortMode == 'recent',
        child: const Text('Nedavno dodano')),
      CheckedPopupMenuItem(
        value: 'name', checked: sortMode == 'name',
        child: const Text('Po nazivu')),
      CheckedPopupMenuItem(
        value: 'oldest', checked: sortMode == 'oldest',
        child: const Text('Najstarije')),
    ],
  );

  IconData iconFor(VaultItem item) {
    if (item.kind == ItemKind.note) return Icons.description_outlined;
    if (item.kind == ItemKind.card) return Icons.credit_card_outlined;
    if (item.kind == ItemKind.totp) return Icons.verified_user_outlined;
    if (item.title.toLowerCase().contains('github')) return Icons.code;
    if (item.title.toLowerCase().contains('google')) return Icons.g_mobiledata;
    return Icons.key_rounded;
  }

  Widget navMenu({bool drawer = false}) {
    return Container(
      width: drawer ? 280 : 242,
      decoration: const BoxDecoration(
        color: VColors.surface,
        border: Border(right: BorderSide(color: VColors.border))),
      child: Column(children: [
        const Padding(padding: EdgeInsets.fromLTRB(18, 20, 12, 22),
          child: VeldigoLogo(size: 36)),
        Expanded(child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final (label, icon) in _navigation)
              Padding(padding: const EdgeInsets.symmetric(vertical: 2),
                child: Material(color: Colors.transparent,
                  child: ListTile(
                  dense: true,
                  selected: page == label,
                  selectedColor: VColors.accent,
                  selectedTileColor: const Color(0xFF093846),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                  leading: Icon(icon, size: 20),
                  title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onTap: () {
                    if (drawer) { Navigator.of(context).pop(); }
                    navigate(label);
                  },
                ))),
          ],
        )),
        const Padding(padding: EdgeInsets.all(16),
          child: Text('VELDIGO • VAŠI PODACI. UVIJEK VAŠI.',
            style: TextStyle(color: VColors.muted, fontSize: 10))),
      ]),
    );
  }

  bool get pageHasOwnHeading => const {
    'Generator', 'Sigurnost', 'Autentifikator',
    'Sigurnosna kopija', 'Postavke', 'Kategorije',
  }.contains(page);

  Widget titleBar(bool desktop) {
    if ((pageHasOwnHeading || page == 'Kartice') && !desktop) {
      return const SizedBox.shrink();
    }
    if (pageHasOwnHeading && desktop) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(26, 16, 18, 0),
        child: Row(children: [
          const Expanded(child: Text('VELDIGO  /  PASSWORD MANAGER',
            style: TextStyle(color: VColors.muted, fontSize: 10,
              letterSpacing: 2, fontWeight: FontWeight.w700))),
          IconButton(
            tooltip: 'Zaključaj trezor',
            icon: const Icon(Icons.lock_outline, color: VColors.accent),
            onPressed: widget.store.lock),
        ]),
      );
    }
    return Padding(
    padding: EdgeInsets.fromLTRB(desktop ? 26 : 22,
      desktop ? 25 : 14, desktop ? 18 : 22,
      desktop ? 16 : 12),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (page == 'Trezor' && !desktop)
          Text.rich(const TextSpan(children: [
              TextSpan(text: 'Dobrodošao u '),
              TextSpan(text: 'Veldigo',
                style: TextStyle(color: VColors.accent)),
            ]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: VColors.text, fontSize: 24,
              fontWeight: FontWeight.w800))
        else
          Text(page == 'Trezor' ? 'Moj trezor' : page,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(page == 'Trezor' && !desktop
            ? 'Tvoj siguran trezor za sve lozinke i važne podatke.'
            : 'Vaši podaci, sigurno na jednom mjestu.',
          style: const TextStyle(color: VColors.muted, fontSize: 13)),
      ])),
      if (desktop && (page == 'Trezor' || page == 'Sve lozinke'))
        VPrimaryButton(label: 'Nova lozinka',
          icon: Icons.add, onPressed: () => edit()),
      if (desktop) ...[
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Zaključaj trezor',
          icon: const Icon(Icons.lock_outline, color: VColors.accent),
          onPressed: widget.store.lock,
        ),
      ],
    ]),
  );
  }

  void selectItem(VaultItem item, bool desktop) {
    setState(() => selectedId = item.id);
    if (!desktop) {
      // The Android design uses an entire account-details screen, not a
      // small centered modal. Listen to the live vault so edits immediately
      // refresh this view and permanently erased records cannot leak back
      // onto the screen from a stale captured VaultItem.
      showDialog<void>(context: context, builder: (dialogContext) =>
        Dialog.fullscreen(child: AnimatedBuilder(
          animation: widget.store,
          builder: (ctx, _) {
            if (!widget.store.isUnlocked) {
              // Modal routes sit above MaterialApp's home. An authentication
              // lock must dismiss *all* old detail/editor routes, otherwise
              // stale account content could remain over the unlock screen.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext, rootNavigator: true)
                      .popUntil((route) => route.isFirst);
                }
              });
              return const ColoredBox(color: VColors.background);
            }
            final live = widget.store.items
                .where((record) => record.id == item.id).firstOrNull;
            if (live == null) {
              return Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Natrag',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
                body: const Center(
                  child: Text('Zapis više nije dostupan.')),
              );
            }
            final heading = switch (live.kind) {
              ItemKind.note => 'Detalji bilješke',
              ItemKind.card => 'Detalji kartice',
              ItemKind.totp => 'Detalji autentifikatora',
              _ => 'Detalji lozinke',
            };
            return Scaffold(
              backgroundColor: VColors.background,
              appBar: AppBar(
                backgroundColor: VColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Natrag',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                title: const VeldigoLogo(size: 29),
                actions: [
                  if (!live.trashed)
                    IconButton(
                      tooltip: 'Uredi zapis',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => edit(original: live),
                    ),
                ],
              ),
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    Text(heading, style: Theme.of(ctx).textTheme.headlineMedium),
                    const SizedBox(height: 18),
                    detail(live),
                  ],
                ),
              ),
            );
          },
        )));
    }
  }

  Widget listPage({ItemKind? kind, bool favorites = false,
      bool trash = false}) {
    final items = filtered(kind: kind, favorites: favorites, trash: trash);
    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 780;
      final wideDesktop = desktop && MediaQuery.sizeOf(context).width >= 1280;
      final selected = items.where((e) => e.id == selectedId).firstOrNull ??
          (desktop && items.isNotEmpty ? items.first : null);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(children: [
          if (!desktop && constraints.maxHeight > 460 &&
              page == 'Trezor' && !favorites && kind == null) ...[
            VPanel(
              padding: const EdgeInsets.symmetric(
                horizontal: 13, vertical: 15),
              child: InkWell(
              onTap: () => navigate('Sigurnost'),
              child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: VColors.accent.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shield_outlined,
                  size: 39, color: VColors.accent)),
              const SizedBox(width: 13),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trezor je zaštićen za druge',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 3),
                  Text('Tvoji podaci su sigurno šifrirani.',
                    style: TextStyle(color: VColors.muted, fontSize: 12)),
                ],
              )),
              const Icon(Icons.chevron_right, color: VColors.muted),
            ]))),
            const SizedBox(height: 12),
          ],
          if (kind != ItemKind.totp)
            Row(children: [
              Expanded(child: TextField(
                controller: search,
                onChanged: (value) => setState(() => query = value),
                decoration: InputDecoration(
                  hintText: !desktop && page == 'Trezor'
                    ? 'Pretraži lozinke...' :
                    'Pretraži zapise, korisnička imena i kategorije…',
                  prefixIcon: const Icon(Icons.search)),
              )),
              if (!desktop && page == 'Trezor') ...[
                const SizedBox(width: 6),
                sortMenu(compact: true),
              ],
            ]),
          const SizedBox(height: 14),
          if (kind == null && !favorites && page == 'Trezor' &&
              constraints.maxHeight > 380)
            Row(children: [
              _stat('Lozinke', widget.store.items.where(
                (e) => !e.trashed && e.kind == ItemKind.password).length,
                Icons.key_outlined),
              const SizedBox(width: 10),
              _stat('Bilješke', widget.store.items.where(
                (e) => !e.trashed && e.kind == ItemKind.note).length,
                Icons.description_outlined),
              const SizedBox(width: 10),
              _stat('Upozorenja', widget.store.items.where((e) =>
                !e.trashed && e.kind == ItemKind.password && e.secret.length < 12).length,
                Icons.notifications_active_outlined),
            ]),
          if (kind == null && !favorites && page == 'Trezor') ...[
            const SizedBox(height: 14),
            if (constraints.maxHeight > 550 && !desktop)
              Row(children: [
                const Expanded(child: Text('Moje lozinke',
                  style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold))),
                Text(switch (sortMode) {
                  'name' => 'Po nazivu',
                  'oldest' => 'Najstarije',
                  _ => 'Nedavno dodano',
                }, style: const TextStyle(color: VColors.muted,
                  fontSize: 10)),
                sortMenu(),
              ]),
          ],
          Expanded(child: Row(children: [
            Expanded(child: Container(
              decoration: desktop ? BoxDecoration(
                color: VColors.surface,
                border: Border.all(color: VColors.border),
                borderRadius: BorderRadius.circular(13),
              ) : null,
              padding: EdgeInsets.symmetric(
                horizontal: desktop ? 6 : 0,
                vertical: desktop ? 4 : 0),
              child: items.isEmpty
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Text('Nema zapisa. Dodajte prvi zapis pomoću gumba Dodaj.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: VColors.muted))))
                : ListView.separated(
                    itemCount: items.length + (wideDesktop ? 1 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    separatorBuilder: (_, _) =>
                        SizedBox(height: wideDesktop ? 3 : 6),
                    itemBuilder: (_, i) {
                      if (wideDesktop && i == 0) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                          child: Row(children: [
                            Expanded(child: Text('USLUGA / KORISNIK',
                              style: TextStyle(color: VColors.muted,
                                letterSpacing: .8, fontSize: 10))),
                            SizedBox(width: 100, child: Text('KATEGORIJA',
                              style: TextStyle(color: VColors.muted,
                                letterSpacing: .8, fontSize: 10))),
                            SizedBox(width: 100, child: Text('AŽURIRANO',
                              style: TextStyle(color: VColors.muted,
                                letterSpacing: .8, fontSize: 10))),
                            SizedBox(width: 92),
                          ]),
                        );
                      }
                      final item = items[i - (wideDesktop ? 1 : 0)];
                      return _accountTile(
                        item, desktop, selected?.id == item.id);
                    },
                  ),
            )),
            if (desktop) ...[
              const SizedBox(width: 14),
              SizedBox(width: 342,
                child: selected == null
                  ? const VPanel(child: Center(
                    child: Text('Odaberite zapis za detalje.',
                      style: TextStyle(color: VColors.muted))))
                  : detail(selected)),
            ],
          ])),
        ]),
      );
    });
  }

  /// Render locally from vector/icons. Never load remote account favicons:
  /// private vault service names must not leave the device through image URLs.
  Widget _serviceMark(VaultItem item, {required double iconSize}) {
    if (item.kind != ItemKind.password) {
      return Icon(iconFor(item), color: VColors.accent, size: iconSize);
    }
    final service = item.title.toLowerCase();
    if (service.contains('netflix')) {
      return Text('N', style: TextStyle(
        color: const Color(0xFFE50914), fontSize: iconSize + 6,
        fontWeight: FontWeight.w900, height: 1));
    }
    if (service.contains('google')) {
      return Text('G', style: TextStyle(
        color: const Color(0xFF4285F4), fontSize: iconSize + 4,
        fontWeight: FontWeight.w900, height: 1));
    }
    if (service.contains('microsoft')) {
      return SizedBox(width: iconSize, height: iconSize,
        child: Column(children: [
          Expanded(child: Row(children: [
            Expanded(child: ColoredBox(color: Color(0xFFF25022))),
            const SizedBox(width: 2),
            Expanded(child: ColoredBox(color: Color(0xFF7FBA00))),
          ])),
          const SizedBox(height: 2),
          Expanded(child: Row(children: [
            Expanded(child: ColoredBox(color: Color(0xFF00A4EF))),
            const SizedBox(width: 2),
            Expanded(child: ColoredBox(color: Color(0xFFFFB900))),
          ])),
        ]));
    }
    if (service.contains('github')) {
      return Icon(Icons.code_rounded, color: VColors.text,
        size: iconSize);
    }
    return Icon(Icons.key_rounded, color: VColors.accent,
      size: iconSize);
  }

  /// Shared reference-style account card. Only masks are drawn for secrets.
  Widget _accountTile(VaultItem item, bool desktop, bool selected) {
    final compact = !desktop && MediaQuery.sizeOf(context).width < 365;
    final wideDesktop = desktop && MediaQuery.sizeOf(context).width >= 1280;
    Future<void> action(String name) async {
      if (!mounted || !widget.store.isUnlocked) return;
      switch (name) {
        case 'open':
          selectItem(item, desktop);
        case 'copy':
          if (item.secret.isNotEmpty) await copySecret(item.secret);
        case 'edit':
          await edit(original: item);
        case 'favorite':
          try {
            final current = widget.store.items.where(
              (record) => record.id == item.id).firstOrNull;
            if (current != null && !current.trashed) {
              await widget.store.put(current.copyWith(
                favorite: !current.favorite,
                updatedAt: DateTime.now().toUtc()));
            }
          } catch (_) {
            notifyUser('Favorit nije spremljen.');
          }
        case 'trash':
          await remove(item);
        case 'restore':
          await recoverItem(item);
      }
    }
    return Material(
      color: selected ? const Color(0xFF103343) : VColors.surface,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => selectItem(item, desktop),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: wideDesktop ? 8 : 10,
            vertical: wideDesktop ? 4 : (desktop ? 9 : 12)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: selected
                ? VColors.accent.withValues(alpha: .38) : VColors.border),
          ),
          child: Row(children: [
            Container(
              width: compact ? 37 : wideDesktop ? 32 : 45,
              height: compact ? 37 : wideDesktop ? 32 : 45,
              decoration: BoxDecoration(
                color: VColors.raised,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: _serviceMark(item,
                iconSize: compact ? 21 : wideDesktop ? 19 : 25)),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(item.username.isEmpty ? item.category : item.username,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11,
                    color: VColors.muted)),
                if (!desktop) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    if (item.kind == ItemKind.password)
                      const Expanded(child: Text('••••••••••',
                        style: TextStyle(fontSize: 12,
                          letterSpacing: 1.3, color: VColors.muted)))
                    else
                      const Spacer(),
                    VCategoryPill(name: item.category),
                  ]),
                ],
              ],
            )),
            if (wideDesktop) ...[
              SizedBox(width: 100, child: VCategoryPill(name: item.category)),
              SizedBox(width: 100, child: Text(
                '${item.updatedAt.toLocal().day}.'
                '${item.updatedAt.toLocal().month}.'
                '${item.updatedAt.toLocal().year}.',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: VColors.muted, fontSize: 10))),
            ],
            if (item.secret.isNotEmpty && !item.trashed && !compact)
              IconButton(
                tooltip: 'Kopiraj',
                visualDensity: VisualDensity.compact,
                onPressed: () => action('copy'),
                icon: const Icon(Icons.copy_outlined,
                  color: VColors.muted, size: 18),
              ),
            PopupMenuButton<String>(
              tooltip: 'Više opcija',
              icon: const Icon(Icons.more_vert,
                color: VColors.muted, size: 20),
              onSelected: action,
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'open',
                  child: Text('Otvori detalje')),
                if (!item.trashed) ...[
                  if (item.secret.isNotEmpty)
                    const PopupMenuItem(value: 'copy',
                      child: Text('Kopiraj')),
                  const PopupMenuItem(value: 'edit',
                    child: Text('Uredi')),
                  PopupMenuItem(value: 'favorite',
                    child: Text(item.favorite
                      ? 'Ukloni iz favorita' : 'Dodaj u favorite')),
                  const PopupMenuItem(value: 'trash',
                    child: Text('Premjesti u Koš')),
                ] else
                  const PopupMenuItem(value: 'restore',
                    child: Text('Vrati iz Koša')),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  /// Statistics stay aligned on narrow 320dp Android screens.
  Widget _stat(String label, int value, IconData icon) =>
    Expanded(child: LayoutBuilder(builder: (context, bounds) {
      final compact = bounds.maxWidth < 110;
      final indicatorColor = label == 'Bilješke' ? VColors.blue
        : label == 'Upozorenja' ? VColors.warning : VColors.accent;
      return VPanel(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 10, vertical: compact ? 9 : 12),
        child: Row(children: [
          Container(
            width: compact ? 25 : 32, height: compact ? 25 : 32,
            decoration: BoxDecoration(
              color: indicatorColor.withValues(alpha: .10),
              shape: BoxShape.circle),
            child: Icon(icon, color: indicatorColor,
              size: compact ? 16 : 20)),
          SizedBox(width: compact ? 4 : 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, children: [
              Text('$value', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800,
                  fontSize: compact ? 16 : 19)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: VColors.muted,
                  fontSize: compact ? 9 : 10)),
            ])),
        ]),
      );
    }));

  Widget detail(VaultItem item) => VPanel(
    child: SingleChildScrollView(child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A3D50), Color(0xFF092338),
                VColors.surface]),
            border: Border.all(color: VColors.accent
              .withValues(alpha: .18)),
            borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            CircleAvatar(radius: 24,
              backgroundColor: VColors.background,
              child: Icon(iconFor(item),
                color: VColors.accent, size: 26)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(item.website.isEmpty
                    ? item.category : item.website,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: VColors.muted, fontSize: 11)),
              ],
            )),
          ]),
        ),
        const SizedBox(height: 14),
        if (item.username.isNotEmpty)
          _info('Korisničko ime', item.username,
            onCopy: () => copySecret(item.username)),
        if (item.secret.isNotEmpty) _secretField(item),
        if (item.kind == ItemKind.card && item.expiry.isNotEmpty)
          _info('Vrijedi do', item.expiry),
        if (item.kind == ItemKind.card && item.cvv.isNotEmpty)
          _SecretDetails(key: ValueKey('cvv-${item.id}'),
            recordId: item.id, secret: item.cvv,
            label: 'CVV', copy: copySecret),
        if (item.website.isNotEmpty)
          _info('Web-adresa', item.website, onCopy: () => copySecret(item.website)),
        if (item.notes.isNotEmpty)
          _info(item.kind == ItemKind.note ? 'Bilješka' : 'Dodatno',
            item.notes),
        const SizedBox(height: 10),
        Text('Ažurirano: ${item.updatedAt.toLocal().day}.${item.updatedAt.toLocal().month}.'
          '${item.updatedAt.toLocal().year}.',
          style: const TextStyle(color: VColors.muted, fontSize: 11)),
        const SizedBox(height: 22),
        if (item.trashed) ...[
          VPrimaryButton(label: 'Vrati iz Koša',
            icon: Icons.restore,
            onPressed: () => recoverItem(item)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => eraseItem(item),
            icon: const Icon(Icons.delete_forever, color: VColors.red),
            label: const Text('Trajno ukloni',
              style: TextStyle(color: VColors.red))),
        ] else ...[
          if (item.kind == ItemKind.password && item.secret.isNotEmpty) ...[
            VPrimaryButton(label: 'Kopiraj lozinku',
              icon: Icons.copy_outlined,
              onPressed: () => copySecret(item.secret)),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: () => edit(original: item),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Uredi')),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => remove(item),
            icon: const Icon(Icons.delete_outline, color: VColors.red),
            label: const Text('Premjesti u Koš',
              style: TextStyle(color: VColors.red))),
        ],
      ],
    )),
  );

  Widget _info(String label, String value, {VoidCallback? onCopy}) =>
    Padding(padding: const EdgeInsets.only(bottom: 10),
      child: VPanel(padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(
                color: VColors.muted, fontSize: 11)),
              const SizedBox(height: 5),
              SelectableText(value),
            ])),
          if (onCopy != null) IconButton(onPressed: onCopy,
            tooltip: 'Kopiraj', icon: const Icon(Icons.copy_outlined)),
        ])));

  Widget _secretField(VaultItem item) => _SecretDetails(
    key: ValueKey('secret-${item.id}'), recordId: item.id,
    secret: item.secret, label: item.kind == ItemKind.card
      ? 'Broj kartice' : item.kind == ItemKind.totp
      ? 'TOTP ključ' : 'Lozinka', copy: copySecret);

  Future<void> addCategory() async {
    final controller = TextEditingController();
    try {
      final accepted = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nova kategorija'),
          content: TextField(controller: controller,
            maxLength: 48, autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Naziv kategorije')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Odustani')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Spremi')),
          ],
        ));
      if (accepted != true) return;
      final name = controller.text.trim();
      if (name.isEmpty || availableCategories.any(
          (old) => old.toLowerCase() == name.toLowerCase())) {
        notifyUser('Unesite jedinstveni naziv kategorije.');
        return;
      }
      await widget.store.put(VaultItem(
        id: 'category-${DateTime.now().microsecondsSinceEpoch}-'
          '${Random.secure().nextInt(1 << 32)}',
        kind: ItemKind.category,
        title: name,
        updatedAt: DateTime.now().toUtc(),
      ));
      notifyUser('Kategorija je spremljena.');
    } catch (_) {
      notifyUser('Spremanje kategorije nije uspjelo.');
    } finally {
      controller.dispose();
    }
  }

  Widget categoriesPage() {
    return LayoutBuilder(builder: (context, constraints) {
      final fullWidth = constraints.maxWidth < 670;
      final tileWidth = fullWidth
          ? constraints.maxWidth - 32
          : (constraints.maxWidth - 44) / 2;
      final categories = availableCategories.where((category) =>
        category.toLowerCase().contains(query.trim().toLowerCase())).toList();
      return ListView(padding: const EdgeInsets.all(16), children: [
        const VSectionHeader(
          title: 'Kategorije',
          subtitle: 'Organizirajte pristupne podatke prema kategorijama.',
        ),
        TextField(
          controller: search,
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(
            hintText: 'Pretraži kategorije…',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        if (categories.isEmpty)
          const VPanel(child: Text('Nema kategorija za unesenu pretragu.',
            style: TextStyle(color: VColors.muted))),
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final category in categories)
            SizedBox(width: tileWidth, child: Material(
              color: VColors.surface,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () => setState(() {
                  categoryFilter = category;
                  page = 'Trezor';
                  query = '';
                  search.clear();
                }),
                child: VPanel(padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 16),
                  child: Row(children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: VColors.accent.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.folder_outlined,
                        color: VColors.accent, size: 19)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(category, maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: VColors.raised,
                        borderRadius: BorderRadius.circular(15)),
                      child: Text('${widget.store.items.where((item) =>
                        !item.trashed && item.kind != ItemKind.category &&
                        item.category == category).length}',
                        style: const TextStyle(
                          color: VColors.accent, fontSize: 12)),
                    ),
                  ]),
                ),
              ),
            )),
        ]),
        const SizedBox(height: 18),
        VPrimaryButton(label: 'Dodaj kategoriju',
          icon: Icons.add, onPressed: addCategory),
      ]);
    });
  }

  /// An encrypted payment-card overview. Only the last four digits are ever
  /// rendered on the list; the full number and CVV remain behind the detail
  /// view, which is dismissed automatically when the vault is locked.
  Widget cardsPage() {
    final cards = filtered(kind: ItemKind.card);
    if (MediaQuery.sizeOf(context).width >= 860) {
      return listPage(kind: ItemKind.card);
    }
    final featured = cards.firstOrNull;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const VSectionHeader(
        title: 'Kartice',
        subtitle: 'Pohranjene osjetljive podatke kartica čuvamo u trezoru.'),
      TextField(
        controller: search,
        onChanged: (value) => setState(() => query = value),
        decoration: const InputDecoration(
          hintText: 'Pretraži spremljene kartice…',
          prefixIcon: Icon(Icons.search)),
      ),
      const SizedBox(height: 16),
      if (featured != null) ...[
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => selectItem(featured, false),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 175),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF05646C), Color(0xFF0B3556),
                    Color(0xFF081C32)]),
                border: Border.all(
                  color: VColors.accent.withValues(alpha: .40)),
                borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Text('VELDIGO', style: TextStyle(
                      letterSpacing: 2, fontWeight: FontWeight.w800,
                      color: VColors.text)),
                    Spacer(),
                    Icon(Icons.credit_card_outlined, color: VColors.text),
                  ]),
                  const SizedBox(height: 35),
                  Text('••••  ••••  ••••  ${_lastFour(featured.secret)}',
                    style: const TextStyle(
                      fontSize: 20, letterSpacing: 2.0,
                      fontWeight: FontWeight.w700, color: VColors.text)),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: Text(
                      featured.username.isEmpty ? featured.title
                          : featured.username,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VColors.muted, fontSize: 12))),
                    if (featured.expiry.isNotEmpty)
                      Text(featured.expiry,
                        style: const TextStyle(
                          color: VColors.muted, fontSize: 12)),
                  ]),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (cards.isEmpty)
        const VPanel(child: Text(
          'Nema spremljenih kartica. Dodajte prvu karticu u šifrirani trezor.',
          style: TextStyle(color: VColors.muted))),
      for (final card in cards)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Material(color: VColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: VColors.border),
                borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.credit_card_outlined,
                color: VColors.accent),
              title: Text(card.title, maxLines: 1,
                overflow: TextOverflow.ellipsis),
              subtitle: Text('Samo zadnje četiri znamenke: ${_lastFour(card.secret)}'),
              trailing: const Icon(Icons.chevron_right,
                color: VColors.muted),
              onTap: () => selectItem(card, false),
            ))),
      const SizedBox(height: 10),
      VPrimaryButton(label: 'Dodaj karticu', icon: Icons.add,
        onPressed: () => edit(kind: ItemKind.card)),
    ]);
  }

  String _lastFour(String secret) {
    final numbers = secret.replaceAll(RegExp(r'[^0-9]'), '');
    return numbers.isEmpty
        ? '••••'
        : numbers.substring(numbers.length > 4 ? numbers.length - 4 : 0)
            .padLeft(4, '•');
  }

  Widget content() => switch (page) {
    'Trezor' => listPage(),
    'Sve lozinke' => listPage(kind: ItemKind.password),
    'Favoriti' => listPage(favorites: true),
    'Sigurne bilješke' => listPage(kind: ItemKind.note),
    'Kartice' => cardsPage(),
    'Kategorije' => categoriesPage(),
    'Autentifikator' => AuthenticatorPage(
      items: filtered(kind: ItemKind.totp),
      onAdd: () => edit(kind: ItemKind.totp)),
    'Generator' => const GeneratorPage(),
    'Sigurnost' => SecurityPage(items: widget.store.items
      .where((item) => !item.trashed).toList()),
    'Koš' => listPage(trash: true),
    'Sigurnosna kopija' => BackupPage(store: widget.store,
      onMessage: notifyUser),
    'Postavke' => SettingsPage(store: widget.store,
      onMessage: notifyUser),
    _ => listPage(),
  };

  Widget extraButton() {
    if (page == 'Sigurne bilješke' || page == 'Kartice') {
      return VPrimaryButton(
        label: page == 'Kartice' ? 'Nova kartica' : 'Nova bilješka',
        icon: Icons.add, onPressed: () => edit(
          kind: page == 'Kartice' ? ItemKind.card : ItemKind.note));
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 860;
    // When the soft keyboard is visible, prioritize the editing/search area.
    // Keep the desktop navigation unchanged; only the mobile chrome collapses.
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (desktop) { return Scaffold(
      body: Row(children: [
        navMenu(),
        Expanded(child: Column(children: [
          titleBar(true),
          if (page == 'Sigurne bilješke' || page == 'Kartice')
            Align(alignment: Alignment.centerRight, child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 22, 12),
              child: extraButton())),
          Expanded(child: content()),
        ])),
      ]),
    );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: VColors.background,
        leadingWidth: 49,
        leading: Builder(builder: (ctx) => IconButton(
          tooltip: 'Otvori izbornik',
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          icon: const VeldigoLogo(size: 25, showName: false),
        )),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('VELDIGO', style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w800, letterSpacing: 2.6,
              color: VColors.text)),
            SizedBox(height: 1),
            Text('VAŠE LOZINKE, UVIJEK SIGURNE',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 7, letterSpacing: 1,
                color: VColors.muted)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Zaključaj trezor',
            icon: const Icon(Icons.lock_outline, color: VColors.accent),
            onPressed: widget.store.lock,
          ),
        ]),
      drawer: Drawer(backgroundColor: VColors.surface,
        child: SafeArea(child: navMenu(drawer: true))),
      body: Column(children: [
        if (!keyboardVisible) titleBar(false),
        if (!keyboardVisible && page == 'Sigurne bilješke')
          Padding(padding: const EdgeInsets.only(bottom: 10),
            child: extraButton()),
        Expanded(child: content()),
      ]),
      floatingActionButton: (page == 'Trezor' || page == 'Sve lozinke')
          ? FloatingActionButton(
              tooltip: 'Dodaj novu lozinku',
              backgroundColor: VColors.accent,
              foregroundColor: VColors.background,
              onPressed: () => edit(),
              child: const Icon(Icons.add, size: 30))
          : null,
      bottomNavigationBar: keyboardVisible ? null : NavigationBar(
        height: 64,
        backgroundColor: VColors.background,
        selectedIndex: switch (page) {
          'Generator' => 1, 'Sigurnost' => 2, 'Postavke' => 3, _ => 0,
        },
        onDestinationSelected: (i) =>
          navigate(['Trezor', 'Generator', 'Sigurnost', 'Postavke'][i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.lock_outline), label: 'Trezor'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined),
            label: 'Generator'),
          NavigationDestination(icon: Icon(Icons.shield_outlined),
            label: 'Sigurnost'),
          NavigationDestination(icon: Icon(Icons.settings_outlined),
            label: 'Postavke'),
        ],
      ),
    );
  }
}

class _SecretDetails extends StatefulWidget {
  final String recordId;
  final String secret;
  final String label;
  final Future<void> Function(String) copy;
  const _SecretDetails({super.key, required this.recordId,
    required this.secret, required this.label, required this.copy});
  @override
  State<_SecretDetails> createState() => _SecretDetailsState();
}

class _SecretDetailsState extends State<_SecretDetails> {
  bool visible = false;

  @override
  void didUpdateWidget(covariant _SecretDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recordId != widget.recordId ||
        oldWidget.secret != widget.secret ||
        oldWidget.label != widget.label) {
      visible = false;
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: VPanel(padding: const EdgeInsets.all(12),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.label, style: const TextStyle(
              color: VColors.muted, fontSize: 11)),
            const SizedBox(height: 4),
            Text(visible ? widget.secret : '••••••••••••',
              overflow: TextOverflow.ellipsis),
          ])),
        IconButton(tooltip: visible ? 'Sakrij' : 'Prikaži',
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility_outlined),
          onPressed: () => setState(() => visible = !visible)),
        IconButton(tooltip: 'Kopiraj', icon: const Icon(Icons.copy_outlined),
          onPressed: () => widget.copy(widget.secret)),
      ])));
}
