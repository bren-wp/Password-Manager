import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/password_generator.dart';
import '../core/totp.dart';
import '../core/vault_item.dart';
import '../core/vault_store.dart';
import 'brand.dart';
import 'encrypted_backup_input.dart';

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});
  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  int length = 20;
  bool upper = true, lower = true, numbers = true, symbols = true;
  late String generated = PasswordGenerator.generate();

  void regenerate() {
    try {
      setState(() => generated = PasswordGenerator.generate(
        length: length, uppercase: upper,
        lowercase: lower, numbers: numbers, special: symbols));
    } on ArgumentError {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Odaberite barem jednu skupinu znakova.')));
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      VPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        const Text('GENERIRANA LOZINKA',
          style: TextStyle(color: VColors.muted, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        SelectableText(generated, style: const TextStyle(
          color: VColors.accent, fontSize: 23,
          fontWeight: FontWeight.bold, letterSpacing: 1)),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          IconButton(tooltip: 'Kopiraj lozinku',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              final copied = generated;
              await Clipboard.setData(ClipboardData(text: copied));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(
                    'Kopirano. Međuspremnik se čisti nakon 30 sekundi.')));
              }
              Future<void>.delayed(const Duration(seconds: 30), () async {
                try {
                  final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
                  if (clipboard?.text == copied) {
                    await Clipboard.setData(const ClipboardData(text: ''));
                  }
                } catch (_) {
                  // Clipboard may be inaccessible while the app is suspended.
                }
              });
            }),
          IconButton(tooltip: 'Nova lozinka',
            icon: const Icon(Icons.refresh), onPressed: regenerate),
        ]),
        const LinearProgressIndicator(
          value: 1, color: VColors.accent, backgroundColor: VColors.border),
        const SizedBox(height: 9),
        const Text('Nasumična lozinka iz sigurnog generatora',
          style: TextStyle(color: VColors.muted, fontSize: 12)),
      ])),
      const SizedBox(height: 16),
      VPanel(child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [const Text('Duljina lozinke'),
            Text('$length', style: const TextStyle(
              color: VColors.accent, fontWeight: FontWeight.bold))]),
        Slider(min: 8, max: 64, divisions: 56, value: length.toDouble(),
          activeColor: VColors.accent,
          onChanged: (value) => setState(() => length = value.toInt())),
        SwitchListTile.adaptive(
          title: const Text('Velika slova (A–Z)'), value: upper,
          onChanged: (v) => setState(() => upper = v)),
        SwitchListTile.adaptive(
          title: const Text('Mala slova (a–z)'), value: lower,
          onChanged: (v) => setState(() => lower = v)),
        SwitchListTile.adaptive(
          title: const Text('Brojevi (0–9)'), value: numbers,
          onChanged: (v) => setState(() => numbers = v)),
        SwitchListTile.adaptive(
          title: const Text('Posebni znakovi'), value: symbols,
          onChanged: (v) => setState(() => symbols = v)),
      ])),
      const SizedBox(height: 16),
      VPrimaryButton(label: 'Generiraj novu lozinku',
        icon: Icons.auto_awesome, onPressed: regenerate),
    ],
  );
}

class SecurityPage extends StatelessWidget {
  final List<VaultItem> items;
  const SecurityPage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final passwords = items.where((e) => e.kind == ItemKind.password).toList();
    final weak = passwords.where((e) => e.secret.length < 12 ||
        !RegExp(r'[0-9]').hasMatch(e.secret) ||
        !RegExp(r'[^a-zA-Z0-9]').hasMatch(e.secret)).toList();
    final counts = <String, int>{};
    for (final item in passwords) {
      counts[item.secret] = (counts[item.secret] ?? 0) + 1;
    }
    final repeated = passwords.where((e) => (counts[e.secret] ?? 0) > 1).length;
    final score = passwords.isEmpty ? 100 :
      max(0, 100 - (weak.length * 12 + repeated * 8));
    return ListView(padding: const EdgeInsets.all(16), children: [
      VPanel(child: Row(children: [
        SizedBox(width: 85, height: 85, child: Stack(
          fit: StackFit.expand, children: [
            CircularProgressIndicator(value: score / 100, strokeWidth: 8,
              color: VColors.accent, backgroundColor: VColors.border),
            Center(child: Text('$score', style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold))),
          ])),
        const SizedBox(width: 20),
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sigurnosni centar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 7),
          Text('Lokalna procjena duljine i ponavljanja lozinki. '
            'Ne provjerava stvarne proboje računa niti aktivnu 2FA zaštitu.',
            style: TextStyle(color: VColors.muted)),
        ])),
      ])),
      const SizedBox(height: 14),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _metric('Ukupno lozinki', passwords.length, Icons.key),
        _metric('Slabije lozinke', weak.length, Icons.warning_amber),
        _metric('Ponovljene lozinke', repeated, Icons.repeat),
        _metric('Ostale bilješke',
          items.where((e) => e.kind == ItemKind.note).length,
          Icons.description_outlined),
      ]),
      const SizedBox(height: 18),
      const Text('Preporuke za poboljšanje',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      if (weak.isEmpty && repeated == 0)
        const VPanel(child: Text(
          'Nisu pronađeni kratki ili ponovljeni zapisi prema lokalnim pravilima. '
          'I dalje preporučujemo višefaktorsku autentifikaciju.')),
      for (final item in weak)
        Padding(padding: const EdgeInsets.only(bottom: 8),
          child: VPanel(child: ListTile(
            leading: const Icon(Icons.warning_amber, color: Colors.orange),
            title: Text(item.title),
            subtitle: const Text('Provjerite jačinu i duljinu lozinke.')))),
      if (repeated > 0)
        VPanel(child: Text(
          'Pronađeno je $repeated zapisa s ponovljenim lozinkama. '
          'Koristite jedinstvenu lozinku za svaki servis.')),
    ]);
  }

  static Widget _metric(String title, int count, IconData icon) =>
      SizedBox(width: 205, child: VPanel(child: Row(children: [
        Icon(icon, color: VColors.accent),
        const SizedBox(width: 10),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('$count', style: const TextStyle(
            fontSize: 23, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(
              fontSize: 12, color: VColors.muted))])),
      ])));
}

class AuthenticatorPage extends StatefulWidget {
  final List<VaultItem> items;
  final VoidCallback onAdd;
  const AuthenticatorPage({super.key, required this.items,
    required this.onAdd});
  @override
  State<AuthenticatorPage> createState() => _AuthenticatorPageState();
}

class _AuthenticatorPageState extends State<AuthenticatorPage> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1),
      (_) { if (mounted) setState(() {}); });
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  Future<String> code(String source, int epoch) =>
      Totp.generate(source, epoch);

  @override
  Widget build(BuildContext context) {
    final epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const VPanel(child: Text('Jednokratni TOTP kodovi generiraju se lokalno. '
        'Račun možete dodati ručnim unosom Base32 tajnog ključa. '
        'Koristite vlastiti Base32 tajni ključ.')),
      const SizedBox(height: 15),
      for (final item in widget.items)
        Padding(padding: const EdgeInsets.only(bottom: 10),
          child: VPanel(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold)),
            Text(item.username,
              style: const TextStyle(color: VColors.muted)),
            const SizedBox(height: 14),
            FutureBuilder<String>(
              future: code(item.secret, epoch),
              builder: (ctx, snapshot) => Text(snapshot.hasError
                  ? 'Neispravan TOTP ključ'
                  : (snapshot.data == null ? '··· ···' :
                    '${snapshot.data!.substring(0, 3)} '
                    '${snapshot.data!.substring(3)}'),
                style: const TextStyle(
                  fontSize: 29, color: VColors.accent,
                  fontWeight: FontWeight.bold, letterSpacing: 3))),
            Text('Novi kod za ${30 - epoch % 30} s',
              style: const TextStyle(color: VColors.muted)),
          ]))),
      const SizedBox(height: 8),
      VPrimaryButton(label: 'Dodaj autentifikator',
        icon: Icons.add, onPressed: widget.onAdd),
    ]);
  }
}

class BackupPage extends StatefulWidget {
  final VaultStore store;
  final ValueChanged<String> onMessage;
  const BackupPage({super.key, required this.store,
    required this.onMessage});
  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool busy = false;

  Future<void> export() async {
    setState(() => busy = true);
    try {
      final data = Uint8List.fromList(await widget.store.encryptedBackup());
      final path = await widget.store.withExternalFilePicker(
        () => FilePicker.saveFile(
          dialogTitle: 'Spremi šifrirani trezor',
          fileName: 'Veldigo-backup.veldigo',
          bytes: data,
          mimeType: 'application/octet-stream',
        ),
      );
      if (path != null) { widget.onMessage('Šifrirana kopija je spremljena.'); }
    } catch (_) {
      widget.onMessage('Izvoz nije uspio.');
    } finally {
      if (mounted) { setState(() => busy = false); }
    }
  }

  Future<void> restore() async {
    if (busy) { return; }
    setState(() => busy = true);
    try {
      final chosen = await widget.store.withExternalFilePicker(
        () => FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: ['veldigo']),
      );
      if (chosen == null || !mounted) { return; }
      final bytes = await EncryptedBackupInput.read(
        chosen.readAsByteStream(),
        reportedSize: chosen.lengthSync() ?? await chosen.length(),
      );
      if (!mounted) { return; }
      final controller = TextEditingController();
      try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Vrati šifriranu kopiju?'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Ovo će ZAMIJENITI sve trenutačne zapise. '
              'Unesite glavnu lozinku te sigurnosne kopije.'),
            const SizedBox(height: 16),
            TextField(controller: controller, obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Lozinka sigurnosne kopije')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Odustani')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Vrati trezor')),
          ],
        ),
      );
      if (confirmed == true) {
        await widget.store.restore(bytes, controller.text);
        widget.onMessage('Trezor je uspješno vraćen.');
      }
      } finally {
        controller.dispose();
      }
    } catch (_) {
      widget.onMessage('Kopija nije učitana. Provjerite datoteku i lozinku.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16), children: [
    VPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
      const Icon(Icons.enhanced_encryption, color: VColors.accent, size: 40),
      const SizedBox(height: 10),
      const Text('Sigurnosna kopija i prijenos',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      const Text('Izvezite svoj trezor kao šifriranu .veldigo datoteku. '
        'Datoteka se može otvoriti na Androidu i Windowsu pomoću '
        'iste glavne lozinke.',
        style: TextStyle(color: VColors.muted)),
      const SizedBox(height: 18),
      VPrimaryButton(label: 'Izradi sigurnosnu kopiju',
        icon: Icons.file_download_outlined,
        onPressed: busy ? null : export),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: busy ? null : restore,
        icon: const Icon(Icons.restore),
        label: const Text('Vrati trezor iz kopije')),
      const SizedBox(height: 10),
      const Text('Važno: vraćanje zamjenjuje postojeći trezor. '
        'Spremite aktualnu kopiju prije vraćanja.',
        style: TextStyle(color: VColors.muted, fontSize: 12)),
    ])),
  ]);
}

class SettingsPage extends StatelessWidget {
  Future<void> changePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    try {
      final approved = await showDialog<bool>(context: context, builder: (ctx) =>
        AlertDialog(
          title: const Text('Promijeni glavnu lozinku'),
          content: SizedBox(width: 400, child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Nakon promjene izradite novu šifriranu sigurnosnu '
                'kopiju. Stare kopije koriste prethodnu lozinku.'),
              const SizedBox(height: 12),
              TextField(controller: current, obscureText: true,
                decoration: const InputDecoration(labelText: 'Trenutačna lozinka')),
              const SizedBox(height: 12),
              TextField(controller: next, obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova lozinka')),
              const SizedBox(height: 12),
              TextField(controller: confirm, obscureText: true,
                decoration: const InputDecoration(labelText: 'Potvrdite novu lozinku')),
            ]),
          )),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Odustani')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Spremi promjenu')),
          ],
        ));
      if (approved != true) return;
      if (next.text.length < 12 || next.text != confirm.text) {
        onMessage('Nova lozinka mora imati barem 12 znakova i podudarati se.');
        return;
      }
      await store.changeMasterPassword(current.text, next.text);
      onMessage('Glavna lozinka je promijenjena. Izradite novu sigurnosnu kopiju.');
    } catch (_) {
      onMessage('Promjena nije uspjela. Provjerite trenutačnu lozinku.');
    } finally {
      current.dispose();
      next.dispose();
      confirm.dispose();
    }
  }
  final VaultStore store;
  final ValueChanged<String> onMessage;
  const SettingsPage({super.key, required this.store,
    required this.onMessage});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16), children: [
    VPanel(child: Column(children: [
      const ListTile(
        leading: Icon(Icons.lock_clock, color: VColors.accent),
        title: Text('Automatsko zaključavanje'),
        subtitle: Text('Odmah nakon prelaska aplikacije u pozadinu')),
      const Divider(color: VColors.border),
      ListTile(
        leading: const Icon(Icons.lock_outline, color: VColors.accent),
        title: const Text('Zaključaj trezor'),
        subtitle: const Text('Zaštitite spremljene podatke'),
        trailing: const Icon(Icons.chevron_right),
        onTap: store.lock),
      const Divider(color: VColors.border),
      ListTile(
        leading: const Icon(Icons.key_outlined, color: VColors.accent),
        title: const Text('Promijeni glavnu lozinku'),
        subtitle: const Text('Zaštitite trezor novom glavnom lozinkom'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => changePassword(context)),
    ])),
    const SizedBox(height: 16),
    VPanel(child: Column(children: [
      ListTile(
        leading: const Icon(Icons.backup_outlined, color: VColors.accent),
        title: const Text('Sigurnosna kopija'),
        subtitle: const Text('Izvoz i uvoz šifriranih podataka'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Sigurnosna kopija')),
            body: BackupPage(store: store, onMessage: onMessage)))),
      ),
    ])),
    const SizedBox(height: 16),
    const VPanel(child: Column(children: [
      ListTile(
        leading: Icon(Icons.info_outline, color: VColors.accent),
        title: Text('Veldigo'),
        subtitle: Text('Android i Windows • Brendigo')),
      ListTile(
        leading: Icon(Icons.shield_outlined, color: VColors.accent),
        title: Text('Privatnost'),
        subtitle: Text('Bez mrežnih računa i prijenosa lozinki na poslužitelj.')),
    ])),
  ]);
}
