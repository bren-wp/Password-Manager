import 'package:flutter/material.dart';

import '../core/vault_store.dart';
import 'brand.dart';

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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 850;
    final form = Form(
      key: formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min, children: [
        if (!desktop) ...[
          const Center(child: VeldigoLogo(size: 70)),
          const SizedBox(height: 38),
        ],
        Text(widget.create ? 'Stvorite sigurni trezor' : 'Dobro došli natrag',
          style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(widget.create
            ? 'Postavite glavnu lozinku za šifriranje svih podataka.'
            : 'Otključajte svoj Veldigo trezor i nastavite gdje ste stali.',
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
        const SizedBox(height: 25),
        const Text('Vaši podaci ostaju pod vašom kontrolom.',
          textAlign: TextAlign.center,
          style: TextStyle(color: VColors.muted, fontSize: 12)),
      ]),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
