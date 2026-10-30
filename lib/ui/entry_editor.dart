import 'dart:math';

import 'package:flutter/material.dart';

import '../core/password_generator.dart';
import '../core/vault_item.dart';
import 'brand.dart';

class EntryEditor extends StatefulWidget {
  final ItemKind kind;
  final VaultItem? original;
  final List<String> availableCategories;
  /// Must complete before the editor closes to prevent losing unsaved secrets.
  final Future<void> Function(VaultItem item)? onPersist;
  const EntryEditor({super.key, required this.kind, this.original,
    this.availableCategories = const [], this.onPersist});

  @override
  State<EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<EntryEditor> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.original?.title ?? '');
  late final username =
      TextEditingController(text: widget.original?.username ?? '');
  late final secret = TextEditingController(text: widget.original?.secret ?? '');
  late final website = TextEditingController(text: widget.original?.website ?? '');
  late final notes = TextEditingController(text: widget.original?.notes ?? '');
  late final expiry = TextEditingController(text: widget.original?.expiry ?? '');
  late final cvv = TextEditingController(text: widget.original?.cvv ?? '');
  late String category = widget.original?.category ?? 'Osobno';
  late bool favorite = widget.original?.favorite ?? false;
  bool showSecret = false;
  late String selectedService = _guessService(widget.original?.title ?? '');
  bool busy = false;
  String? saveError;
  List<String> get categories => <String>{
    'Osobno', 'Posao', 'Zabava', 'Financije', 'Tehnologija', 'Ostalo',
    ...widget.availableCategories, category,
  }.toList();

  @override
  void dispose() {
    title.dispose();
    username.dispose();
    secret.dispose();
    website.dispose();
    notes.dispose();
    expiry.dispose();
    cvv.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() { busy = true; saveError = null; });
    final item = VaultItem(
      id: widget.original?.id ??
          '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
      kind: widget.kind,
      title: title.text.trim(),
      username: username.text.trim(),
      secret: secret.text,
      website: website.text.trim(),
      notes: notes.text,
      expiry: expiry.text,
      cvv: cvv.text,
      category: category,
      favorite: favorite,
      updatedAt: DateTime.now().toUtc(),
    );
    try {
      if (widget.onPersist != null) await widget.onPersist!(item);
      if (mounted) Navigator.of(context).pop(item);
    } catch (_) {
      // Keep the form and all typed credentials intact after a failed save.
      if (mounted) {
        setState(() => saveError = 'Spremanje nije uspjelo. '
          'Vaši uneseni podaci ostaju u ovom obrascu. '
          'Provjerite prostor na disku i pokušajte ponovno.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNote = widget.kind == ItemKind.note;
    final isCard = widget.kind == ItemKind.card;
    final isTotp = widget.kind == ItemKind.totp;
    final label = isNote ? 'bilješku' : isCard ? 'karticu' :
        isTotp ? 'autentifikator' : 'lozinku';
    final mobile = MediaQuery.sizeOf(context).width < 650;
    final fieldGap = mobile ? 11.0 : 14.0;
    // The Android password editor follows the original phone reference.
    // Preserve the existing desktop/card/note/TOTP editors unchanged.
    if (mobile && widget.kind == ItemKind.password) {
      return _mobilePasswordEditor();
    }
    return Dialog(
      backgroundColor: VColors.background,
      insetPadding: mobile ? EdgeInsets.zero : const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mobile ? 0 : 13),
        side: const BorderSide(color: VColors.border)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: mobile ? double.infinity : 580,
          maxHeight: mobile ? double.infinity : 770),
        child: Column(
          mainAxisSize: mobile ? MainAxisSize.max : MainAxisSize.min,
          children: [
          Padding(
            padding: EdgeInsets.fromLTRB(mobile ? 16 : 22, 12, 10, 7),
            child: Row(children: [
              const Icon(Icons.shield_outlined, color: VColors.accent),
              const SizedBox(width: 10),
              Expanded(child: Text(
                widget.original == null
                    ? (mobile && widget.kind == ItemKind.password
                        ? 'Nova lozinka' : 'Dodaj novu $label')
                    : 'Uredi $label',
                style: Theme.of(context).textTheme.titleLarge)),
              IconButton(icon: const Icon(Icons.close),
                tooltip: 'Zatvori', onPressed: busy ? null : () => Navigator.pop(context)),
            ]),
          ),
          const Divider(color: VColors.border),
          if (mobile)
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 8, 22, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Spremite podatke za novi račun ili uslugu.',
                  style: TextStyle(
                    color: VColors.muted, fontSize: 12)),
              ),
            ),
          Flexible(child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 16 : 22, vertical: mobile ? 12 : 22),
            child: Form(key: form, child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextFormField(
                controller: title,
                decoration: InputDecoration(
                  labelText: isNote ? 'Naziv bilješke' : 'Naziv usluge',
                  prefixIcon: const Icon(Icons.label_outline)),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Naziv je obavezan.' : null),
              if (!isNote) ...[
                SizedBox(height: fieldGap),
                TextFormField(
                  controller: username,
                  decoration: InputDecoration(
                    labelText: isCard ? 'Ime vlasnika kartice'
                        : isTotp ? 'Naziv računa / e-mail'
                        : 'Korisničko ime / e-mail',
                    prefixIcon: const Icon(Icons.person_outline))),
              ],
              SizedBox(height: fieldGap),
              if (isNote)
                TextFormField(controller: notes, maxLines: 7,
                  enableIMEPersonalizedLearning: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  decoration: const InputDecoration(
                    labelText: 'Sadržaj bilješke',
                    alignLabelWithHint: true))
              else
                TextFormField(
                  controller: secret,
                  obscureText: !showSecret,
                  enableSuggestions: false, autocorrect: false,
                  enableIMEPersonalizedLearning: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  autofillHints: const [],
                  decoration: InputDecoration(
                    labelText: isCard ? 'Broj kartice' :
                        isTotp ? 'TOTP tajni ključ (Base32)' : 'Lozinka',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (!isCard && !isTotp)
                        IconButton(
                          tooltip: 'Generiraj lozinku',
                          icon: const Icon(Icons.casino_outlined),
                          onPressed: () => setState(() =>
                            secret.text = PasswordGenerator.generate())),
                      IconButton(
                        tooltip: showSecret ? 'Sakrij' : 'Prikaži',
                        icon: Icon(showSecret
                          ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() =>
                          showSecret = !showSecret)),
                    ]),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Unesite vrijednost.' : null),
              if (isCard) ...[
                SizedBox(height: fieldGap),
                TextFormField(controller: expiry,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Vrijedi do (MM/GG)',
                    prefixIcon: Icon(Icons.calendar_today_outlined))),
                SizedBox(height: fieldGap),
                TextFormField(controller: cvv, obscureText: true,
                  autofillHints: const [],
                  keyboardType: TextInputType.number,
                  enableSuggestions: false, autocorrect: false,
                  enableIMEPersonalizedLearning: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  decoration: const InputDecoration(
                    labelText: 'Sigurnosni kod (CVV)',
                    prefixIcon: Icon(Icons.lock_outline))),
              ],
              if (!isNote) ...[
                SizedBox(height: fieldGap),
                if (!isCard && !isTotp) TextFormField(
                  controller: website,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Web-adresa',
                    prefixIcon: Icon(Icons.link))),
                if (!isTotp) SizedBox(height: fieldGap),
                if (!isTotp && !isNote)
                  TextFormField(controller: notes, maxLines: 3,
                    enableIMEPersonalizedLearning: false,
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    decoration: const InputDecoration(
                      labelText: 'Dodatna sigurna bilješka (neobavezno)',
                      alignLabelWithHint: true)),
              ],
              SizedBox(height: fieldGap),
              DropdownButtonFormField<String>(
                initialValue: categories.contains(category) ? category : 'Ostalo',
                decoration: const InputDecoration(
                  labelText: 'Kategorija',
                  prefixIcon: Icon(Icons.folder_outlined)),
                items: categories.map((cat) => DropdownMenuItem(
                  value: cat, child: Text(cat))).toList(),
                onChanged: (value) => setState(() => category = value!)),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dodaj u favorite'),
                activeTrackColor: VColors.accent,
                value: favorite,
                onChanged: (value) => setState(() => favorite = value)),
            ])),
          )),
          if (saveError != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(saveError!, style: const TextStyle(color: VColors.red))),
          Padding(
            padding: EdgeInsets.fromLTRB(
              mobile ? 16 : 20, 11, mobile ? 16 : 20, 14),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: busy ? null : () => Navigator.pop(context),
                child: const Text('Odustani'))),
              const SizedBox(width: 12),
              Expanded(child: VPrimaryButton(
                label: busy ? 'Spremanje…' : 'Spremi',
                onPressed: busy ? null : save,
                icon: Icons.save_outlined)),
            ]),
          ),
        ]),
      ),
    );
  }
  String _guessService(String name) {
    final lower = name.toLowerCase();
    for (final key in ['github', 'google', 'microsoft', 'apple', 'discord']) {
      if (lower.contains(key)) return key;
    }
    return 'web';
  }

  void _chooseService(String key) {
    if (busy) return;
    const preset = <String, (String, String)>{
      'github': ('GitHub', 'https://github.com'),
      'google': ('Google', 'https://accounts.google.com'),
      'microsoft': ('Microsoft', 'https://account.microsoft.com'),
      'apple': ('Apple', 'https://account.apple.com'),
      'discord': ('Discord', 'https://discord.com'),
    };
    setState(() => selectedService = key);
    final suggestion = preset[key];
    // Presets assist entry and are not separate accounts or remote lookups.
    // The generic options never erase text the user has already entered.
    if (suggestion != null) {
      title.text = suggestion.$1;
      website.text = suggestion.$2;
    }
  }

  Widget _mobileSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: VColors.border),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0C293C), VColors.surface],
      ),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: VColors.muted)),
        const SizedBox(height: 5),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 35, height: 35,
            decoration: BoxDecoration(
              color: VColors.raised,
              borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: VColors.text, size: 18),
          ),
          const SizedBox(width: 9),
          Expanded(child: content),
        ]),
      ]),
  );

  Widget _mobilePasswordEditor() {
    const services = <(String, String, IconData)>[
      ('github', 'GitHub', Icons.code),
      ('google', 'Google', Icons.g_mobiledata),
      ('microsoft', 'Microsoft', Icons.window),
      ('apple', 'Apple', Icons.apple),
      ('discord', 'Discord', Icons.sports_esports_outlined),
      ('web', 'Web', Icons.language),
      ('other', 'Ostalo', Icons.more_horiz),
    ];
    const compactField = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 11, vertical: 12),
    );
    return Dialog(
      backgroundColor: VColors.background,
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height -
          MediaQuery.viewInsetsOf(context).bottom,
        child: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 5),
          child: Row(children: [
            IconButton(
              tooltip: 'Natrag',
              onPressed: busy ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: VColors.text)),
            Expanded(child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VeldigoLogo(size: 31),
                const SizedBox(height: 2),
                Text('YOUR SECRETS. SECURE.',
                  style: TextStyle(color: VColors.muted,
                    fontSize: 7, letterSpacing: 1.5)),
              ],
            ))),
            const SizedBox(width: 48),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          key: const ValueKey('editor-mobile-scroll'),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.original == null
                    ? 'Nova lozinka' : 'Uredi lozinku',
                  style: const TextStyle(
                    color: VColors.text,
                    fontSize: 25, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                const Text('Spremite podatke za novi račun ili uslugu.',
                  style: TextStyle(color: VColors.muted, fontSize: 12)),
                const SizedBox(height: 14),
                Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VColors.surface,
                    border: Border.all(color: VColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Odaberite ikonu', style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 3),
                      const Text('Pomaže vam brže prepoznati uslugu.',
                        style: TextStyle(
                          color: VColors.muted, fontSize: 11)),
                      const SizedBox(height: 9),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final service in services)
                            Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: Tooltip(
                              message: 'Odaberi ' + service.$2,
                              child: InkWell(
                                key: ValueKey('service-' + service.$1),
                                onTap: () => _chooseService(service.$1),
                                borderRadius: BorderRadius.circular(14),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: selectedService == service.$1
                                      ? VColors.raised : VColors.surface,
                                    border: Border.all(
                                      color: selectedService == service.$1
                                          ? VColors.accent : VColors.border,
                                      width: selectedService == service.$1
                                          ? 1.5 : 1),
                                    borderRadius: BorderRadius.circular(14)),
                                  child: Icon(service.$3, size: 23,
                                    color: selectedService == service.$1
                                      ? VColors.accent : VColors.text)),
                              ),
                            )),
                        ])),
                    ]),
                ),
                _mobileSection(
                  title: 'Usluga / naziv *',
                  icon: Icons.label_rounded,
                  content: TextFormField(
                    key: const ValueKey('editor-title'),
                    controller: title,
                    decoration: compactField.copyWith(
                      hintText: 'Naziv usluge'),
                    validator: (value) =>
                      value == null || value.trim().isEmpty
                        ? 'Naziv je obavezan.' : null,
                  ),
                ),
                _mobileSection(
                  title: 'Web-adresa',
                  icon: Icons.link,
                  content: TextFormField(
                    key: const ValueKey('editor-website'),
                    controller: website,
                    keyboardType: TextInputType.url,
                    decoration: compactField.copyWith(
                      hintText: 'https://primjer.hr'),
                  ),
                ),
                _mobileSection(
                  title: 'Korisničko ime',
                  icon: Icons.person,
                  content: TextFormField(
                    key: const ValueKey('editor-username'),
                    controller: username,
                    decoration: compactField.copyWith(
                      hintText: 'Korisničko ime / e-mail'),
                  ),
                ),
                _mobileSection(
                  title: 'Lozinka *',
                  icon: Icons.lock,
                  content: Column(children: [
                    TextFormField(
                      key: const ValueKey('editor-secret'),
                      controller: secret,
                      obscureText: !showSecret,
                      enableSuggestions: false,
                      autocorrect: false,
                      enableIMEPersonalizedLearning: false,
                      smartDashesType: SmartDashesType.disabled,
                      smartQuotesType: SmartQuotesType.disabled,
                      autofillHints: const [],
                      decoration: compactField.copyWith(
                        hintText: 'Lozinka',
                        suffixIconConstraints:
                          const BoxConstraints(minHeight: 38),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: showSecret ? 'Sakrij' : 'Prikaži',
                              icon: Icon(showSecret
                                ? Icons.visibility_off : Icons.visibility,
                                size: 19),
                              onPressed: () => setState(
                                () => showSecret = !showSecret),
                            ),
                            IconButton(
                              tooltip: 'Generiraj lozinku',
                              icon: const Icon(
                                Icons.casino_outlined, size: 19),
                              onPressed: busy ? null : () {
                                secret.text = PasswordGenerator.generate();
                              },
                            ),
                          ]),
                      ),
                      validator: (value) =>
                        value == null || value.isEmpty
                          ? 'Unesite vrijednost.' : null,
                    ),
                    const SizedBox(height: 7),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: secret,
                      builder: (context, text, _) {
                        final value = text.text;
                        final groups = [
                          RegExp(r'[A-Z]').hasMatch(value),
                          RegExp(r'[a-z]').hasMatch(value),
                          RegExp(r'[0-9]').hasMatch(value),
                          RegExp(r'[^A-Za-z0-9]').hasMatch(value),
                        ].where((match) => match).length;
                        final score = value.isEmpty ? 0
                          : value.runes.length >= 16 && groups >= 3 ? 4
                          : value.runes.length >= 12 && groups >= 2 ? 3
                          : value.runes.length >= 8 ? 2 : 1;
                        return Row(children: [
                          for (var i = 0; i < 4; i++) ...[
                            if (i > 0) const SizedBox(width: 3),
                            Expanded(child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: i < score
                                  ? VColors.accent : VColors.border,
                                borderRadius: BorderRadius.circular(5)),
                            )),
                          ],
                          const SizedBox(width: 9),
                          Text(value.isEmpty ? 'Unesite lozinku'
                            : score >= 4 ? 'Procjena: vrlo jaka'
                            : score >= 3 ? 'Procjena: jaka'
                            : 'Procjena: slaba',
                            style: const TextStyle(
                              color: VColors.accent, fontSize: 10)),
                        ]);
                      },
                    ),
                  ]),
                ),
                _mobileSection(
                  title: 'Kategorija',
                  icon: Icons.folder_open,
                  content: DropdownButtonFormField<String>(
                    key: const ValueKey('editor-category'),
                    initialValue: categories.contains(category)
                      ? category : 'Ostalo',
                    decoration: compactField,
                    isExpanded: true,
                    items: categories.map((cat) => DropdownMenuItem(
                      value: cat, child: Text(cat))).toList(),
                    onChanged: busy ? null : (value) =>
                      setState(() => category = value!),
                  ),
                ),
                _mobileSection(
                  title: 'Sigurna bilješka (neobavezno)',
                  icon: Icons.description,
                  content: TextFormField(
                    key: const ValueKey('editor-notes'),
                    controller: notes,
                    maxLength: 500,
                    maxLines: 2,
                    enableIMEPersonalizedLearning: false,
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    decoration: compactField.copyWith(
                      hintText: 'Dodajte privatnu bilješku',
                      alignLabelWithHint: true),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 3),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: VColors.surface,
                    border: Border.all(color: VColors.border),
                    borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile.adaptive(
                    key: const ValueKey('editor-favorite'),
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.star,
                      color: VColors.text, size: 22),
                    title: const Text('Dodaj u favorite',
                      style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700)),
                    subtitle: const Text('Brži pristup ovoj lozinci.',
                      style: TextStyle(fontSize: 10,
                        color: VColors.muted)),
                    activeTrackColor: VColors.accent,
                    value: favorite,
                    onChanged: busy ? null :
                      (value) => setState(() => favorite = value),
                  ),
                ),
              ],
            ),
          ),
        )),
        if (saveError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(saveError!,
              style: const TextStyle(color: VColors.red, fontSize: 11)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 12),
          child: SizedBox(
            width: double.infinity,
            child: VPrimaryButton(
              label: busy ? 'Spremanje…' :
                widget.original == null ? 'Spremi lozinku' : 'Spremi promjene',
              icon: Icons.lock_outline,
              onPressed: busy ? null : save,
            ),
          ),
        ),
      ]))),
    );
  }

}
