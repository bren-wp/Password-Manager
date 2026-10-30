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
              enableIMEPersonalizedLearning: false,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
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
    final size = MediaQuery.sizeOf(context);
    final desktop = size.width >= 850;
    final compactMobile = !desktop && size.height < 730;
    final form = Form(
      key: formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min, children: [
        if (!desktop) ...[
          if (widget.create) ...[
            Row(children: [
              const Icon(Icons.shield_outlined,
                color: VColors.accent, size: 18),
              const Spacer(),
              const Text('VELDIGO',
                style: TextStyle(fontSize: 13, color: VColors.text,
                  fontWeight: FontWeight.w800, letterSpacing: 3)),
              const Spacer(),
              const Text('1 / 1',
                style: TextStyle(color: VColors.muted, fontSize: 12)),
            ]),
            SizedBox(height: compactMobile ? 16 : 22),
          ],
          Center(child: VeldigoLogo(
            size: widget.create ? (compactMobile ? 98 : 116)
                : (compactMobile ? 126 : 151),
            showName: false)),
          SizedBox(height: widget.create ? 9 : 14),
          if (!widget.create) ...[
            const Center(child: Text('VELDIGO',
              style: TextStyle(
                fontSize: 27, color: VColors.text, letterSpacing: 6,
                fontWeight: FontWeight.w800))),
            const SizedBox(height: 4),
            const Center(child: Text('PASSWORD MANAGER',
              style: TextStyle(
                color: VColors.muted, fontSize: 9, letterSpacing: 2.6))),
          ],
          SizedBox(height: widget.create ? 17 : 27),
        ],
        Text(widget.create ? 'Zaštitite svoj trezor' : 'Dobro došli natrag',
          textAlign: desktop ? TextAlign.start : TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(widget.create
            ? 'Postavite glavnu lozinku za pristup svim svojim podacima.'
            : 'Otključajte svoj Veldigo trezor',
          textAlign: desktop ? TextAlign.start : TextAlign.center,
          style: const TextStyle(color: VColors.muted)),
        SizedBox(height: widget.create ? 17 : 30),
        TextFormField(
          controller: password, obscureText: !visible,
          autofillHints: const [], enableSuggestions: false,
          autocorrect: false, enableIMEPersonalizedLearning: false,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
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
            enableIMEPersonalizedLearning: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            autofillHints: const [],
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
          const SizedBox(height: 14),
          const VPanel(
            padding: EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                  color: VColors.accent, size: 21),
                SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Glavnu lozinku ne možemo oporaviti.',
                      style: TextStyle(color: VColors.text,
                        fontWeight: FontWeight.w700, fontSize: 12)),
                    SizedBox(height: 4),
                    Text('Vaša glavna lozinka štiti lokalno šifrirani trezor. '
                      'Ako je zaboravite, bez nje ne možemo vratiti '
                      'pristup podacima ili šifriranoj kopiji.',
                      style: TextStyle(color: VColors.muted,
                        fontSize: 11, height: 1.35)),
                  ],
                )),
              ],
            ),
          ),
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
          const SizedBox(height: 13),
          OutlinedButton.icon(
            onPressed: busy ? null : recover,
            icon: const Icon(Icons.settings_backup_restore),
            label: const Text('Oporavi iz lokalne sigurnosne kopije'),
          ),
          if (!desktop) ...[
            const SizedBox(height: 13),
            TextButton(
              onPressed: busy ? null : () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Zaboravili ste lozinku?'),
                  content: const Text('Glavnu lozinku nije moguće '
                    'poništiti. Za pristup trezoru potrebna je ispravna '
                    'glavna lozinka; lokalna šifrirana sigurnosna kopija '
                    'također zahtijeva lozinku kojom je zaštićena.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Razumijem')),
                  ],
                )),
              child: const Text('Zaboravili ste lozinku?',
                style: TextStyle(
                  color: VColors.accent,
                  fontSize: 12,
                  decoration: TextDecoration.underline)),
            ),
          ],
        ],
        SizedBox(height: widget.create ? 18 : 20),
        if (!desktop && !widget.create) ...[
          const SizedBox(height: 8),
          const Row(children: [
            Expanded(child: Divider(color: VColors.border)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12),
              child: VeldigoLogo(size: 23, showName: false)),
            Expanded(child: Divider(color: VColors.border)),
          ]),
          const SizedBox(height: 8),
        ],
        Text(widget.create
            ? 'Vaši podaci ostaju pod vašom kontrolom.'
            : 'Vaše lozinke ostaju samo vaše.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: VColors.muted, fontSize: 12)),
      ]),
    );

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: desktop ? Alignment.center : Alignment.topCenter,
          child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            desktop ? 24 : 22,
            desktop ? 24 : (compactMobile ? 12 : (widget.create ? 16 : 38)),
            desktop ? 24 : 22,
            24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: desktop ? 1060 : 460),
            child: desktop
              ? VPanel(
                  padding: EdgeInsets.zero,
                  child: Row(children: [
                    Expanded(child: Container(
                      padding: const EdgeInsets.all(50),
                      constraints: const BoxConstraints(minHeight: 600),
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(-.1, -.6), radius: 1.3,
                          colors: [
                            Color(0xFF0C4352),
                            Color(0xFF08293D),
                            VColors.background,
                          ]),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(18))),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          VeldigoLogo(size: 124, showName: false),
                          SizedBox(height: 12),
                          Text('V E L D I G O', style: TextStyle(
                            color: VColors.text, fontSize: 23,
                            letterSpacing: 3, fontWeight: FontWeight.w800)),
                          SizedBox(height: 6),
                          Text('VAŠE LOZINKE. VAŠA KONTROLA.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: VColors.muted,
                              fontSize: 10, letterSpacing: 1.7)),
                          SizedBox(height: 36),
                          _AuthBenefit(
                            icon: Icons.lock_outline,
                            title: 'Sigurno spremanje',
                            detail: 'Sve vaše lozinke na jednom mjestu.'),
                          SizedBox(height: 12),
                          _AuthBenefit(
                            icon: Icons.verified_user_outlined,
                            title: 'Potpuna privatnost',
                            detail: 'Vaši podaci šifrirani su samo lokalno.'),
                          SizedBox(height: 12),
                          _AuthBenefit(
                            icon: Icons.desktop_windows_outlined,
                            title: 'Uvijek dostupno',
                            detail: 'Na vašim uređajima, bez računa.'),
                        ],
                      ),
                    )),
                    Expanded(child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 44, vertical: 28), child: form)),
                  ]))
              : form,
          ),
        )),
      ),
    );
  }
}

/// Descriptive, noninteractive security features: never advertise a
/// biometric unlock method unless a hardware-backed authenticator is wired.
class _AuthBenefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _AuthBenefit({
    required this.icon, required this.title, required this.detail,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: VColors.accent.withValues(alpha: .09),
          border: Border.all(color: VColors.border),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: VColors.accent, size: 19),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            color: VColors.text, fontSize: 12,
            fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(detail, style: const TextStyle(
            color: VColors.muted, fontSize: 10)),
        ],
      )),
    ],
  );
}
