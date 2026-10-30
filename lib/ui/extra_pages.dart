import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/sensitive_clipboard.dart';

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
  bool avoidSimilar = true;

  double get estimatedStrength {
    final alphabet = (upper ? (avoidSimilar ? PasswordGenerator.upper.length : PasswordGenerator.fullUpper.length) : 0) +
        (lower ? (avoidSimilar ? PasswordGenerator.lower.length : PasswordGenerator.fullLower.length) : 0) +
        (numbers ? (avoidSimilar ? PasswordGenerator.digits.length : PasswordGenerator.fullDigits.length) : 0) +
        (symbols ? PasswordGenerator.symbols.length : 0);
    if (alphabet == 0) return 0;
    final entropyBits = length * (log(alphabet) / ln2);
    return (entropyBits / 110).clamp(0.0, 1.0).toDouble();
  }
  late String generated = PasswordGenerator.generate(length: length);
  late double _generatedStrength = estimatedStrength;
  // This history exists only in the unlocked widget state. It is never
  // persisted, logged, or copied into the encrypted vault implicitly.
  final _history = <({String password, double strength, DateTime createdAt})>[];

  void regenerate() {
    try {
      final next = PasswordGenerator.generate(
        length: length, uppercase: upper,
        lowercase: lower, numbers: numbers, special: symbols,
        avoidSimilar: avoidSimilar);
      setState(() {
        _history.insert(0, (
          password: generated,
          strength: _generatedStrength,
          createdAt: DateTime.now(),
        ));
        if (_history.length > 5) _history.removeLast();
        generated = next;
        _generatedStrength = estimatedStrength;
      });
    } on ArgumentError {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Odaberite barem jednu skupinu znakova.')));
    }
  }

  void changeCharacterSet(String type, bool enabled) {
    final remaining = (type == 'upper' ? enabled : upper) ||
        (type == 'lower' ? enabled : lower) ||
        (type == 'numbers' ? enabled : numbers) ||
        (type == 'symbols' ? enabled : symbols);
    if (!remaining) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Najmanje jedna skupina znakova mora ostati uključena.')));
      return;
    }
    setState(() {
      switch (type) {
        case 'upper': upper = enabled;
        case 'lower': lower = enabled;
        case 'numbers': numbers = enabled;
        case 'symbols': symbols = enabled;
      }
    });
    regenerate();
  }

  Future<void> copyGenerated() => _copyPassword(generated);

  Future<void> _copyPassword(String copied) async {
    try {
      await SensitiveClipboard.copy(copied);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kopirano. Međuspremnik se čisti nakon 30 sekundi.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Međuspremnik nije dostupan. Pokušajte ponovno.')));
      }
    }
  }

  /// Five equal segments match the reference design on both platforms.
  /// The value is a local estimate, not a breach-database security verdict.
  Widget _strengthSegments(double strength) => Row(
    key: const ValueKey('veldigo-strength-segments'),
    children: [
      for (var i = 0; i < 5; i++) ...[
        if (i > 0) const SizedBox(width: 4),
        Expanded(child: Container(
          key: ValueKey('veldigo-strength-segment-$i'),
          height: 7,
          decoration: BoxDecoration(
            color: strength >= (i + 1) / 5
                ? VColors.accent : VColors.border,
            borderRadius: BorderRadius.circular(7),
          ),
        )),
      ],
    ],
  );

  /// A full-row, accessible toggle: tapping its title or switch must work.
  /// Keep SwitchListTile semantics for keyboard/assistive-technology users.
  Widget _characterOption(String symbol, String name, String subtitle,
      bool checked, ValueChanged<bool> onChanged) =>
    SwitchListTile.adaptive(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 7),
      secondary: SizedBox(width: 31, child: Center(
        child: Text(symbol, style: const TextStyle(
          fontSize: 12, color: VColors.accent,
          fontWeight: FontWeight.w800)))),
      title: Text(name, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600)),
      subtitle: subtitle.isEmpty ? null : Text(subtitle,
        style: const TextStyle(
          color: VColors.muted, fontSize: 10)),
      value: checked,
      activeTrackColor: VColors.accent,
      onChanged: onChanged,
    );


  Widget _desktopOption(String label, bool checked,
      ValueChanged<bool> onChanged) => SizedBox(
    width: 168,
    child: CheckboxListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: VColors.accent,
      checkColor: VColors.background,
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: VColors.text)),
      value: checked,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    ),
  );

  Widget _desktopGenerator(double strength, String strengthName) {
    String quality(double score) => score >= .85
        ? 'Vrlo jaka' : score >= .55 ? 'Jaka' : 'Umjerena';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        const Row(children: [
          Icon(Icons.shuffle, color: VColors.accent, size: 31),
          SizedBox(width: 14),
          Expanded(child: VSectionHeader(
            title: 'Generator lozinki',
            subtitle: 'Generirajte jake i jedinstvene lozinke.',
          )),
        ]),
        const SizedBox(height: 8),
        VPanel(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Generirana lozinka', style: TextStyle(
              color: VColors.muted, fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 2, 6, 2),
              decoration: BoxDecoration(
                color: VColors.background,
                border: Border.all(color: VColors.border),
                borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Expanded(child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(generated, maxLines: 1,
                    style: const TextStyle(fontSize: 22,
                      letterSpacing: .5, color: VColors.text)),
                )),
                IconButton(
                  tooltip: 'Kopiraj lozinku',
                  onPressed: copyGenerated,
                  icon: const Icon(Icons.copy_outlined,
                    color: VColors.accent)),
                IconButton(
                  tooltip: 'Nova lozinka',
                  onPressed: regenerate,
                  icon: const Icon(Icons.refresh,
                    color: VColors.accent)),
              ]),
            ),
            const SizedBox(height: 11),
            Row(children: [
              const Text('Snaga lozinke', style: TextStyle(
                color: VColors.muted, fontSize: 11)),
              const Spacer(),
              Text(strengthName, style: const TextStyle(
                color: VColors.accent, fontSize: 11,
                fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 5),
            _strengthSegments(strength),
          ],
        )),
        const SizedBox(height: 12),
        VPanel(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Duljina lozinke: $length znakova',
              style: const TextStyle(fontSize: 12, color: VColors.text)),
            Slider(
              value: length.toDouble(),
              // Windows reference range is 8–64; Android keeps 8–128.
              min: 8, max: 64, divisions: 56,
              activeColor: VColors.accent,
              onChanged: (value) {
                setState(() => length = value.toInt());
                regenerate();
              },
            ),
            const Row(children: [
              Text('8', style: TextStyle(
                fontSize: 10, color: VColors.muted)),
              Spacer(),
              Text('64', style: TextStyle(
                fontSize: 10, color: VColors.muted)),
            ]),
            const SizedBox(height: 7),
            Wrap(spacing: 7, runSpacing: 3, children: [
              _desktopOption('Velika slova', upper,
                (v) => changeCharacterSet('upper', v)),
              _desktopOption('Mala slova', lower,
                (v) => changeCharacterSet('lower', v)),
              _desktopOption('Brojevi', numbers,
                (v) => changeCharacterSet('numbers', v)),
              _desktopOption('Posebni znakovi', symbols,
                (v) => changeCharacterSet('symbols', v)),
              _desktopOption('Bez sličnih', avoidSimilar, (v) {
                setState(() => avoidSimilar = v);
                regenerate();
              }),
            ]),
            const SizedBox(height: 10),
            VPrimaryButton(
              label: 'Generiraj novu lozinku',
              icon: Icons.shuffle,
              onPressed: regenerate),
          ],
        )),
        const SizedBox(height: 12),
        VPanel(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.history, size: 18,
                color: VColors.muted),
              const SizedBox(width: 8),
              const Expanded(child: Text(
                'Povijest generiranih lozinki',
                style: TextStyle(fontSize: 12, color: VColors.text,
                  fontWeight: FontWeight.w600))),
              TextButton.icon(
                onPressed: _history.isEmpty ? null :
                    () => setState(_history.clear),
                icon: const Icon(Icons.delete_outline, size: 15),
                label: const Text('Očisti povijest'),
              ),
            ]),
            if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Povijest je prazna. Generirajte novu lozinku.',
                  style: TextStyle(fontSize: 12, color: VColors.muted)),
              ),
            for (final item in _history) Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 1, 4, 1),
                decoration: BoxDecoration(
                  color: VColors.raised,
                  border: Border.all(color: VColors.border),
                  borderRadius: BorderRadius.circular(7)),
                child: Row(children: [
                  const Icon(Icons.shuffle, size: 15, color: VColors.muted),
                  const SizedBox(width: 9),
                  Expanded(child: Text(
                    List.filled(min(18, item.password.length), '•').join(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13, color: VColors.text))),
                  Text(quality(item.strength), style: const TextStyle(
                    color: VColors.accent, fontSize: 11)),
                  const SizedBox(width: 14),
                  Text(
                    '${item.createdAt.hour.toString().padLeft(2, '0')}:'
                    '${item.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10,
                      color: VColors.muted)),
                  IconButton(
                    tooltip: 'Kopiraj lozinku iz povijesti',
                    icon: const Icon(Icons.copy_outlined, size: 17),
                    onPressed: () => _copyPassword(item.password)),
                ]),
              ),
            ),
          ],
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strength = estimatedStrength;
    final strengthName = strength >= .85
        ? 'Vrlo jaka' : strength >= .55 ? 'Jaka' : 'Umjerena';
    if (MediaQuery.sizeOf(context).width >= 850) {
      return _desktopGenerator(strength, strengthName);
    }
    // Keep the primary action visible above Android bottom navigation.
    // Only the settings and strength cards scroll on compact screens.
    return Column(
      children: [
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: [
        const VSectionHeader(
          title: 'Generator lozinki',
          subtitle: 'Izradite snažnu i jedinstvenu lozinku.',
        ),
        VPanel(padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('GENERIRANA LOZINKA', style: TextStyle(
                color: VColors.muted, fontSize: 10, letterSpacing: 1.5)),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF072B3D),
                  border: Border.all(color: VColors.accent
                    .withValues(alpha: .65)),
                  borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Expanded(child: SelectableText(generated,
                    style: const TextStyle(
                      color: VColors.text,
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      letterSpacing: .3))),
                  IconButton(
                    tooltip: 'Kopiraj lozinku',
                    icon: const Icon(Icons.copy_outlined,
                      color: VColors.accent),
                    onPressed: copyGenerated),
                  IconButton(
                    tooltip: 'Nova lozinka',
                    icon: const Icon(Icons.refresh,
                      color: VColors.accent),
                    onPressed: regenerate),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        VPanel(padding: const EdgeInsets.all(13),
          child: Column(children: [
            Row(children: [
              const Expanded(child: Text('DULJINA LOZINKE',
                style: TextStyle(fontSize: 10, letterSpacing: 1.2,
                  color: VColors.muted))),
              Text('$length', style: const TextStyle(
                color: VColors.text,
                fontSize: 13, fontWeight: FontWeight.w800)),
            ]),
            Slider(
              min: 8, max: 128, divisions: 120,
              value: length.toDouble(),
              activeColor: VColors.accent,
              onChanged: (value) {
                setState(() => length = value.toInt());
                regenerate();
              },
            ),
            const Row(children: [
              Text('8', style: TextStyle(
                fontSize: 10, color: VColors.muted)),
              Spacer(),
              Text('128', style: TextStyle(
                fontSize: 10, color: VColors.muted)),
            ]),
          ]),
        ),
        const SizedBox(height: 11),
        VPanel(padding: const EdgeInsets.symmetric(
          horizontal: 11, vertical: 5),
          child: Column(children: [
            _characterOption('Aa', 'Velika slova (A–Z)', '',
              upper, (v) => changeCharacterSet('upper', v)),
            const Divider(height: 1),
            _characterOption('aa', 'Mala slova (a–z)', '',
              lower, (v) => changeCharacterSet('lower', v)),
            const Divider(height: 1),
            _characterOption('123', 'Brojevi (0–9)', '',
              numbers, (v) => changeCharacterSet('numbers', v)),
            const Divider(height: 1),
            _characterOption('!#', 'Posebni znakovi', '(!, @, #, …)',
              symbols, (v) => changeCharacterSet('symbols', v)),
            const Divider(height: 1),
            _characterOption('◉', 'Izbjegni slične znakove',
              'Bez lako zamjenjivih 0, 1, I i l.',
              avoidSimilar, (value) {
                setState(() => avoidSimilar = value);
                regenerate();
              }),
          ]),
        ),
        const SizedBox(height: 11),
        VPanel(padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(child: Text('SNAGA LOZINKE',
                  style: TextStyle(color: VColors.muted,
                    fontSize: 10, letterSpacing: 1.2))),
                Text(strengthName, style: const TextStyle(
                  color: VColors.accent,
                  fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
              const SizedBox(height: 10),
              _strengthSegments(strength),
              const SizedBox(height: 8),
              const Text(
                'Lokalna procjena na temelju duljine i skupa znakova.',
                style: TextStyle(color: VColors.muted, fontSize: 10)),
            ],
          ),
        ),
          ],
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: VPrimaryButton(
              label: 'Generiraj novu lozinku',
              icon: Icons.refresh,
              onPressed: regenerate),
          ),
        ),
      ],
    );
  }
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
    // An empty vault is not a verified 100/100 security result.
    final score = passwords.isEmpty ? 0 :
      max(0, 100 - (weak.length * 12 + repeated * 8));
    return LayoutBuilder(builder: (context, constraints) {
      final metricWidth = (constraints.maxWidth - 44) / 2;
      return ListView(padding: const EdgeInsets.all(16), children: [
      const VSectionHeader(
        title: 'Sigurnosni centar',
        subtitle: 'Pregled sigurnosti vaših spremljenih lozinki.',
      ),
      VPanel(child: Row(children: [
        SizedBox(width: constraints.maxWidth < 360 ? 68 : 85,
          height: constraints.maxWidth < 360 ? 68 : 85,
          child: Stack(
          fit: StackFit.expand, children: [
            CircularProgressIndicator(value: score / 100, strokeWidth: 8,
              color: VColors.accent, backgroundColor: VColors.border),
            Center(child: Text('$score', style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold))),
          ])),
        SizedBox(width: constraints.maxWidth < 360 ? 12 : 20),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sigurnosni rezultat',
            style: TextStyle(fontSize: constraints.maxWidth < 360 ? 16 : 20,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 7),
          const Text('Lokalna procjena duljine i ponavljanja lozinki. '
            'Ne provjerava stvarne proboje računa niti aktivnu 2FA zaštitu.',
            style: TextStyle(color: VColors.muted, fontSize: 12)),
        ])),
      ])),
      const SizedBox(height: 14),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _metric('Ukupno lozinki', passwords.length, Icons.key, metricWidth),
        _metric('Slabije lozinke', weak.length, Icons.warning_amber, metricWidth),
        _metric('Ponovljene lozinke', repeated, Icons.repeat, metricWidth),
        _metric('Ostale bilješke',
          items.where((e) => e.kind == ItemKind.note).length,
          Icons.description_outlined, metricWidth),
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
    });
  }

  static Widget _metric(String title, int count, IconData icon, double width) =>
      SizedBox(width: width, child: VPanel(child: Row(children: [
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

  Future<void> copyCurrentCode(VaultItem item) async {
    final epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final String currentCode;
    try {
      currentCode = await code(item.secret, epoch);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('TOTP ključ nije valjan. Provjerite unos.')));
      }
      return;
    }
    if (!mounted) return;
    try {
      await SensitiveClipboard.copy(
        currentCode, expiry: Duration(seconds: 30 - epoch % 30));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('TOTP kod je kopiran. Međuspremnik će se očistiti.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Međuspremnik nije dostupan. Pokušajte ponovno.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return ListView(padding: const EdgeInsets.all(16), children: [
      VSectionHeader(
        title: 'Autentifikator',
        subtitle: widget.items.isEmpty
            ? 'Dodajte prvi račun s vlastitim TOTP tajnim ključem.'
            : 'Jednokratni kodovi generiraju se lokalno.',
        trailing: IconButton(
          tooltip: 'Dodaj autentifikator',
          onPressed: widget.onAdd,
          icon: const Icon(Icons.add, color: VColors.accent)),
      ),
      const VPanel(child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined,
            size: 24, color: VColors.accent),
          SizedBox(width: 12),
          Expanded(child: Text(
            'TOTP kodovi generiraju se lokalno i ne šalju na poslužitelj. '
            'Dodajte vlastiti Base32 tajni ključ.',
            style: TextStyle(color: VColors.muted, fontSize: 12,
              height: 1.45))),
        ],
      )),
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
            Row(children: [
              Expanded(child: FutureBuilder<String>(
                future: code(item.secret, epoch),
                builder: (ctx, snapshot) => Text(snapshot.hasError
                    ? 'Neispravan TOTP ključ'
                    : (snapshot.data == null ? '··· ···' :
                      '${snapshot.data!.substring(0, 3)} '
                      '${snapshot.data!.substring(3)}'),
                  style: const TextStyle(
                    fontSize: 29, color: VColors.accent,
                    fontWeight: FontWeight.bold, letterSpacing: 3)))),
              IconButton(
                tooltip: 'Kopiraj TOTP kod',
                icon: const Icon(Icons.copy_outlined, color: VColors.muted),
                onPressed: () => copyCurrentCode(item)),
            ]),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (30 - epoch % 30) / 30,
              backgroundColor: VColors.border,
              color: VColors.accent,
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
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
              enableSuggestions: false, autocorrect: false,
              enableIMEPersonalizedLearning: false,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
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
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
    children: [
      const VSectionHeader(
        title: 'Sigurnosna kopija',
        subtitle: 'Sačuvajte svoje podatke i prenesite ih na drugi uređaj.',
      ),
      VPanel(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.file_download_outlined,
              color: VColors.accent, size: 29)),
          const SizedBox(height: 13),
          const Text('Izradi šifriranu kopiju', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 9),
          const Text('Spremite lozinke, sigurne bilješke i ostale zapise '
            'u zaštićenu datoteku.',
            style: TextStyle(color: VColors.muted, fontSize: 12)),
          const SizedBox(height: 17),
          VPrimaryButton(label: 'Izradi sigurnosnu kopiju',
            onPressed: busy ? null : export),
        ],
      )),
      const SizedBox(height: 10),
      VPanel(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.file_upload_outlined,
              color: VColors.accent, size: 29)),
          const SizedBox(height: 13),
          const Text('Vrati trezor iz kopije', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 9),
          const Text('Odaberite šifriranu datoteku i potvrdite '
            'njezinu pristupnu lozinku. Vraćanje zamjenjuje aktivni trezor.',
            style: TextStyle(color: VColors.muted, fontSize: 12)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: busy ? null : restore,
            icon: const Icon(Icons.folder_open_outlined, size: 18),
            label: const Text('Odaberi datoteku')),
        ],
      )),
      const SizedBox(height: 10),
      const VPanel(padding: EdgeInsets.all(13),
        child: Row(children: [
          Icon(Icons.devices_outlined, size: 23, color: VColors.accent),
          SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prijenos između uređaja',
                style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Android ↔ Windows putem šifrirane .veldigo datoteke.',
                style: TextStyle(color: VColors.muted, fontSize: 11)),
            ],
          )),
        ])),
      const SizedBox(height: 10),
      const VPanel(padding: EdgeInsets.all(13),
        child: Row(children: [
          Icon(Icons.shield_outlined, size: 23, color: VColors.accent),
          SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Privatnost prije svega',
                style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Šifrirana datoteka ostaje pod vašom kontrolom. '
                'Čuvajte njezinu lozinku i pohranite je na sigurno.',
                style: TextStyle(color: VColors.muted, fontSize: 11)),
            ],
          )),
        ])),
    ],
  );
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
                enableSuggestions: false, autocorrect: false,
                enableIMEPersonalizedLearning: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                decoration: const InputDecoration(labelText: 'Trenutačna lozinka')),
              const SizedBox(height: 12),
              TextField(controller: next, obscureText: true,
                enableSuggestions: false, autocorrect: false,
                enableIMEPersonalizedLearning: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                decoration: const InputDecoration(labelText: 'Nova lozinka')),
              const SizedBox(height: 12),
              TextField(controller: confirm, obscureText: true,
                enableSuggestions: false, autocorrect: false,
                enableIMEPersonalizedLearning: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
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
    const VSectionHeader(
      title: 'Postavke',
      subtitle: 'Sigurnost, privatnost i upravljanje aplikacijom.',
    ),
    const Text('SIGURNOST', style: TextStyle(
      color: VColors.accent, fontSize: 10, letterSpacing: 1.5,
      fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
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
    const Text('PODACI', style: TextStyle(
      color: VColors.accent, fontSize: 10, letterSpacing: 1.5,
      fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
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
    const Text('APLIKACIJA', style: TextStyle(
      color: VColors.accent, fontSize: 10, letterSpacing: 1.5,
      fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
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
