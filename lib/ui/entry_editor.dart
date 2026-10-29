import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
}
