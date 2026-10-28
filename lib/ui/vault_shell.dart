import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/vault_item.dart';
import '../core/vault_store.dart';
import 'brand.dart';
import 'entry_editor.dart';
import 'extra_pages.dart';

const _navigation = <(String, IconData)>[
  ('Trezor', Icons.lock_outline),
  ('Sve lozinke', Icons.list_alt),
  ('Favoriti', Icons.star_outline),
  ('Kategorije', Icons.grid_view_rounded),
  ('Sigurne bilješke', Icons.description_outlined),
  ('Kartice', Icons.credit_card_outlined),
  ('Autentifikator', Icons.verified_user_outlined),
  ('Generator', Icons.auto_awesome_outlined),
  ('Sigurnost', Icons.shield_outlined),
  ('Sigurnosna kopija', Icons.cloud_upload_outlined),
  ('Postavke', Icons.settings_outlined),
];

class VaultShell extends StatefulWidget {
  final VaultStore store;
  const VaultShell({super.key, required this.store});

  @override
  State<VaultShell> createState() => _VaultShellState();
}

class _VaultShellState extends State<VaultShell> {
  String page = 'Trezor';
  String query = '';
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

  Future<void> edit({ItemKind kind = ItemKind.password, VaultItem? original}) async {
    final item = await showDialog<VaultItem>(
      context: context, barrierDismissible: false,
      builder: (_) => EntryEditor(kind: original?.kind ?? kind, original: original));
    if (item == null) return;
    try {
      await widget.store.put(item);
      if (mounted) setState(() => selectedId = item.id);
      notifyUser('Zapis je sigurno spremljen.');
    } catch (_) {
      notifyUser('Spremanje nije uspjelo.');
    }
  }

  Future<void> remove(VaultItem item) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) =>
      AlertDialog(
        title: const Text('Obrisati zapis?'),
        content: Text('Zapis „${item.title}” bit će trajno uklonjen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši',
              style: TextStyle(color: VColors.red))),
        ]));
    if (yes != true) return;
    try {
      await widget.store.remove(item.id);
      if (mounted) setState(() => selectedId = null);
      notifyUser('Zapis je obrisan.');
    } catch (_) { notifyUser('Brisanje nije uspjelo.'); }
  }

  Future<void> copySecret(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    notifyUser('Kopirano. Međuspremnik se čisti nakon 30 sekundi.');
    // Clear only if it still contains the same value.
    Future<void>.delayed(const Duration(seconds: 30), () async {
      try {
        final current = await Clipboard.getData(Clipboard.kTextPlain);
        if (current?.text == text) { await Clipboard.setData(
          const ClipboardData(text: '')); }
      } catch (_) { /* Clipboard is unavailable while suspended. */ }
    });
  }

  List<VaultItem> filtered({ItemKind? kind, bool favorites = false}) {
    final q = query.toLowerCase().trim();
    return widget.store.items.where((item) =>
        (kind == null || item.kind == kind) &&
        (!favorites || item.favorite) &&
        (categoryFilter == null || item.category == categoryFilter) &&
        (q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.username.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q))).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

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
      width: drawer ? 280 : 244,
      color: VColors.surface,
      child: Column(children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 30, 12, 24),
          child: VeldigoLogo(size: 43)),
        Expanded(child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final (label, icon) in _navigation)
              Padding(padding: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  dense: true,
                  selected: page == label,
                  selectedColor: VColors.accent,
                  selectedTileColor: const Color(0xFF063C47),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                  leading: Icon(icon, size: 20),
                  title: Text(label),
                  onTap: () {
                    if (drawer) { Navigator.of(context).pop(); }
                    navigate(label);
                  },
                )),
          ],
        )),
        const Padding(padding: EdgeInsets.all(16),
          child: Text('VELDIGO • VAŠI PODACI. UVIJEK VAŠI.',
            style: TextStyle(color: VColors.muted, fontSize: 10))),
      ]),
    );
  }

  Widget titleBar(bool desktop) => Padding(
    padding: EdgeInsets.fromLTRB(desktop ? 28 : 14, 23, 22, 14),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(page == 'Trezor' ? 'Moj trezor' : page,
          style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        const Text('Vaši podaci, sigurno na jednom mjestu.',
          style: TextStyle(color: VColors.muted, fontSize: 13)),
      ])),
      if (page == 'Trezor' || page == 'Sve lozinke')
        VPrimaryButton(label: desktop ? 'Nova lozinka' : 'Dodaj',
          icon: Icons.add, onPressed: () => edit()),
    ]),
  );

  void selectItem(VaultItem item, bool desktop) {
    setState(() => selectedId = item.id);
    if (!desktop) {
      showDialog<void>(context: context, builder: (ctx) => Dialog(
        backgroundColor: VColors.background,
        child: ConstrainedBox(constraints: const BoxConstraints(
          maxWidth: 450, maxHeight: 720),
          child: SingleChildScrollView(child: Padding(
            padding: const EdgeInsets.all(14),
            child: detail(item))))));
    }
  }

  Widget listPage({ItemKind? kind, bool favorites = false}) {
    final items = filtered(kind: kind, favorites: favorites);
    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 840;
      final selected = items.where((e) => e.id == selectedId).firstOrNull;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(children: [
          if (kind != ItemKind.totp) TextField(
            controller: search,
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'Pretraži zapise, korisnička imena i kategorije…',
              prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: 14),
          if (kind == null && !favorites && page == 'Trezor')
            Row(children: [
              _stat('Lozinke', widget.store.items.where(
                (e) => e.kind == ItemKind.password).length,
                Icons.key_outlined),
              const SizedBox(width: 10),
              _stat('Bilješke', widget.store.items.where(
                (e) => e.kind == ItemKind.note).length,
                Icons.description_outlined),
              const SizedBox(width: 10),
              _stat('Ukupno', widget.store.items.length,
                Icons.shield_outlined),
            ]),
          if (kind == null && !favorites && page == 'Trezor')
            const SizedBox(height: 14),
          Expanded(child: Row(children: [
            Expanded(child: VPanel(
              padding: EdgeInsets.zero,
              child: items.isEmpty
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Text('Nema zapisa. Dodajte prvi zapis pomoću gumba Dodaj.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: VColors.muted))))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, index) =>
                      const Divider(height: 1, color: VColors.border),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return ListTile(
                        selected: desktop && selected?.id == item.id,
                        selectedTileColor: const Color(0xFF073A43),
                        leading: CircleAvatar(
                          backgroundColor: VColors.raised,
                          child: Icon(iconFor(item), color: VColors.accent)),
                        title: Text(item.title, maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                        subtitle: Text(item.username.isNotEmpty
                            ? item.username : item.category,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: VColors.muted)),
                        trailing: IconButton(
                          tooltip: item.favorite ? 'Ukloni favorit' : 'Favorit',
                          icon: Icon(item.favorite ? Icons.star : Icons.star_border,
                            color: item.favorite ? Colors.amber : VColors.muted),
                          onPressed: () async {
                            await widget.store.put(item.copyWith(
                              favorite: !item.favorite,
                              updatedAt: DateTime.now().toUtc()));
                          }),
                        onTap: () => selectItem(item, desktop),
                      );
                    },
                  ),
            )),
            if (desktop) ...[
              const SizedBox(width: 14),
              SizedBox(width: 340,
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

  Widget _stat(String label, int value, IconData icon) =>
    Expanded(child: VPanel(padding: const EdgeInsets.all(12),
      child: Row(children: [
        Icon(icon, color: VColors.accent),
        const SizedBox(width: 8),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('$value', style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 20)),
            Text(label, style: const TextStyle(
              color: VColors.muted, fontSize: 11))])),
      ])));

  Widget detail(VaultItem item) => VPanel(
    child: SingleChildScrollView(child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          CircleAvatar(radius: 27, backgroundColor: VColors.raised,
            child: Icon(iconFor(item), color: VColors.accent, size: 29)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(item.title, style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold)),
              Text(item.category, style: const TextStyle(
                color: VColors.muted))])),
        ]),
        const SizedBox(height: 20),
        if (item.username.isNotEmpty)
          _info('Korisničko ime', item.username,
            onCopy: () => copySecret(item.username)),
        if (item.secret.isNotEmpty) _secretField(item),
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
        VPrimaryButton(label: 'Uredi', icon: Icons.edit_outlined,
          onPressed: () => edit(original: item)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => remove(item),
          icon: const Icon(Icons.delete_outline, color: VColors.red),
          label: const Text('Obriši', style: TextStyle(color: VColors.red))),
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
    secret: item.secret, label: item.kind == ItemKind.card
      ? 'Broj kartice' : item.kind == ItemKind.totp
      ? 'TOTP ključ' : 'Lozinka', copy: copySecret);

  Widget categoriesPage() {
    const categories = ['Osobno', 'Posao', 'Zabava',
      'Financije', 'Tehnologija', 'Ostalo'];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing: 12, runSpacing: 12, children: [
        for (final category in categories)
          SizedBox(width: 245, child: InkWell(
            onTap: () => setState(() {categoryFilter = category; page = 'Trezor';}),
            child: VPanel(child: Row(children: [
              const Icon(Icons.folder_outlined, color: VColors.accent),
              const SizedBox(width: 12),
              Expanded(child: Text(category)),
              Text('${widget.store.items.where((e) =>
                e.category == category).length}',
                style: const TextStyle(color: VColors.muted)),
            ])),
          )),
      ]),
    ]);
  }

  Widget content() => switch (page) {
    'Trezor' || 'Sve lozinke' => listPage(),
    'Favoriti' => listPage(favorites: true),
    'Sigurne bilješke' => listPage(kind: ItemKind.note),
    'Kartice' => listPage(kind: ItemKind.card),
    'Kategorije' => categoriesPage(),
    'Autentifikator' => AuthenticatorPage(
      items: filtered(kind: ItemKind.totp),
      onAdd: () => edit(kind: ItemKind.totp)),
    'Generator' => const GeneratorPage(),
    'Sigurnost' => SecurityPage(items: widget.store.items),
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
        title: const VeldigoLogo(size: 31)),
      drawer: Drawer(backgroundColor: VColors.surface,
        child: SafeArea(child: navMenu(drawer: true))),
      body: Column(children: [
        titleBar(false),
        if (page == 'Sigurne bilješke' || page == 'Kartice')
          Padding(padding: const EdgeInsets.only(bottom: 10),
            child: extraButton()),
        Expanded(child: content()),
      ]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: VColors.surface,
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
  final String secret;
  final String label;
  final Future<void> Function(String) copy;
  const _SecretDetails({required this.secret, required this.label,
    required this.copy});
  @override
  State<_SecretDetails> createState() => _SecretDetailsState();
}

class _SecretDetailsState extends State<_SecretDetails> {
  bool visible = false;
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
