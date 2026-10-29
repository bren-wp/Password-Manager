import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/vault_store.dart';
import 'brand.dart';
import 'encrypted_backup_input.dart';

class AuthScreen extends StatefulWidget {
  final VaultStore store;
  final bool create;
  const AuthScreen({super.key, required this.store, required this.create});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final formKey = GlobalKey<FormState>();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool busy = false;
  bool visible = false;
  String? error;

  @override
  void dispose() {
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> importBackup() async {
    if (busy) return;
    setState(() { busy = true; error = null; });
    final passphrase = TextEditingController();
    try {
      final chosen = await FilePicker.pickFile(
        type: FileType.custom, allowedExtensions: ['veldigo']);
      if (chosen == null || !mounted) return;
      final bytes = await EncryptedBackupInput.read(
        chosen.readAsByteStream(),
        reportedSize: chosen.lengthSync() ?? await chosen.length(),
      );
      if (!mounted) return;
      final accepted = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Uvezi postojeći trezor'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Uvozite šifriranu sigurnosnu kopiju na novi uređaj. '
              'Unesite njezinu glavnu lozinku.'),
            const SizedBox(height: 14),
            TextField(controller: passphrase, obscureText: true,
              enableSuggestions: false, autocorrect: false,
              decoration: const InputDecoration(labelText: 'Glavna lozinka')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Odustani')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Uvezi trezor')),
          ],
        ));
      if (accepted != true) return;
      await widget.store.importFirstVault(bytes, passphrase.text);
    } catch (_) {
      if (mounted) {
        setState(() => error =
          'Uvoz nije uspio. Provjerite kopiju i glavnu lozinku. '
          'Postojeći podaci nisu obrisani.');
      }
    } finally {
      passphrase.dispose();
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate() || busy) { return; }
    setState(() {busy = true; error = null;});
    try {
      if (widget.create) {
        await widget.store.create(password.text);
      } else {
        await widget.store.unlock(password.text);
      }
    } catch (e) {
      if (mounted) { setState(() => error = e is VaultAuthenticationException
          ? e.toString() : 'Radnja nije uspjela. Provjerite unesene podatke.'); }
    } finally {
      if (mounted) { setState(() => busy = false); }
      password.clear();
      confirmation.clear();
    }
  }

  Future<void> recover() async {
    if (busy || password.text.isEmpty) {
      setState(() => error = 'Unesite glavnu lozinku rezervne kopije.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Oporavak trezora'),
        content: const Text(
          'Oporavak može vratiti stariju verziju zapisa. Trenutačna '
          'datoteka bit će sačuvana za dodatni oporavak. Nastaviti?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Odustani')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Pokušaj oporavak')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { busy = true; error = null; });
    try {
      await widget.store.recoverFromLocalBackup(password.text);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Nije pronađena valjana lokalna kopija za '
            'unesenu lozinku. Postojeći podaci nisu obrisani.');
      }
    } finally {
      password.clear();
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 850;
    final form = Form(
      key: formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min, children: [
        if (!desktop) ...[
          const Center(child: VeldigoLogo(size: 92, showName: false)),
          const SizedBox(height: 16),
          const Center(child: VeldigoLogo(size: 23)),
          const SizedBox(height: 30),
        ],
        Text(widget.create ? 'Zaštitite svoj trezor' : 'Dobro došli natrag',
          textAlign: desktop ? TextAlign.start : TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(widget.create
            ? 'Postavite glavnu lozinku za šifriranje svih podataka.'
            : 'Otključajte svoj Veldigo trezor i nastavite gdje ste stali.',
          textAlign: desktop ? TextAlign.start : TextAlign.center,
          style: const TextStyle(color: VColors.muted)),
        const SizedBox(height: 30),
        TextFormField(
          controller: password, obscureText: !visible,
          autofillHints: const [], enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Glavna lozinka',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: visible ? 'Sakrij' : 'Prikaži',
              icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => visible = !visible)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) { return 'Unesite glavnu lozinku.'; }
            if (widget.create && value.runes.length < 12) {
              return 'Koristite najmanje 12 znakova.';
            }
            return null;
          },
          onFieldSubmitted: (_) => submit(),
        ),
        if (widget.create) ...[
          const SizedBox(height: 14),
          TextFormField(
            controller: confirmation, obscureText: !visible,
            autocorrect: false, enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Potvrdite lozinku',
              prefixIcon: Icon(Icons.verified_user_outlined)),
            validator: (value) => value != password.text
              ? 'Lozinke se ne podudaraju.' : null,
          ),
          const SizedBox(height: 18),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: password,
            builder: (context, value, _) {
              final text = value.text;
              final checks = <(String, bool)>[
                ('Najmanje 12 znakova', text.runes.length >= 12),
                ('Velika i mala slova', RegExp(r'[A-Z]').hasMatch(text) &&
                    RegExp(r'[a-z]').hasMatch(text)),
                ('Broj', RegExp(r'[0-9]').hasMatch(text)),
                ('Poseban znak', RegExp(r'[^a-zA-Z0-9]').hasMatch(text)),
              ];
              final met = checks.where((entry) => entry.$2).length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    const Text('Jačina lozinke',
                      style: TextStyle(color: VColors.muted, fontSize: 12)),
                    const Spacer(),
                    Text(met == 4 ? 'Vrlo jaka' : met >= 2
                      ? 'Srednja' : 'Slaba',
                      style: TextStyle(
                        color: met == 4 ? VColors.accent
                            : met >= 2 ? VColors.warning : VColors.red,
                        fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    for (var i = 0; i < 4; i++) ...[
                      Expanded(child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i < met ? (met == 4
                            ? VColors.accent : VColors.warning)
                            : VColors.border,
                          borderRadius: BorderRadius.circular(5)),
                      )),
                      if (i < 3) const SizedBox(width: 5),
                    ],
                  ]),
                  const SizedBox(height: 12),
                  for (final entry in checks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(children: [
                        Icon(entry.$2 ? Icons.check_circle : Icons.circle_outlined,
                          color: entry.$2 ? VColors.accent : VColors.muted,
                          size: 15),
                        const SizedBox(width: 8),
                        Text(entry.$1, style: const TextStyle(
                          color: VColors.muted, fontSize: 11)),
                      ]),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Glavnu lozinku nije moguće vratiti. I sigurnosne kopije '
            'zahtijevaju istu lozinku. Čuvajte je na sigurnome mjestu.',
            style: TextStyle(color: VColors.muted, fontSize: 12)),
        ],
        if (error != null) ...[
          const SizedBox(height: 14),
          Text(error!, style: const TextStyle(color: VColors.red)),
        ],
        const SizedBox(height: 25),
        VPrimaryButton(
          label: busy ? 'Obrada…' : widget.create
              ? 'Stvori sigurni trezor' : 'Otključaj trezor',
          icon: widget.create ? Icons.shield_outlined : Icons.lock_open,
          onPressed: busy ? null : submit,
        ),
        if (widget.create) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : importBackup,
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Uvezi postojeću šifriranu kopiju')),
        ],
        if (!widget.create) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : recover,
            icon: const Icon(Icons.settings_backup_restore),
            label: const Text('Oporavi iz lokalne sigurnosne kopije'),
          ),
        ],
        const SizedBox(height: 25),
        const Text('Vaši podaci ostaju pod vašom kontrolom.',
          textAlign: TextAlign.center,
          style: TextStyle(color: VColors.muted, fontSize: 12)),
      ]),
    );

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: desktop ? Alignment.center : Alignment.topCenter,
          child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24,
            desktop ? 24 : (MediaQuery.sizeOf(context).height < 690 ? 18 : 52),
            24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: desktop ? 980 : 460),
            child: desktop
              ? VPanel(
                  padding: EdgeInsets.zero,
                  child: Row(children: [
                    Expanded(child: Container(
                      padding: const EdgeInsets.all(50),
                      constraints: const BoxConstraints(minHeight: 530),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF083A49), VColors.surface],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(18))),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          VeldigoLogo(size: 100, showName: false),
                          SizedBox(height: 24),
                          VeldigoLogo(size: 38),
                          SizedBox(height: 18),
                          Text('VAŠE LOZINKE. VAŠA KONTROLA.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: VColors.muted, letterSpacing: 2)),
                          SizedBox(height: 42),
                          Text('Sigurno spremanje • Potpuna privatnost • Bez računa',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: VColors.muted)),
                        ],
                      ),
                    )),
                    Expanded(child: Padding(
                      padding: const EdgeInsets.all(48), child: form)),
                  ]))
              : form,
          ),
        )),
      ),
    );
  }
}
