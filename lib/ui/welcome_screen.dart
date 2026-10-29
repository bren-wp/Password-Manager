import 'package:flutter/material.dart';

import 'brand.dart';

/// The first-run introduction retains both actions within the viewport,
/// including on 320x640 phones and when Android changes the font scale.
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;
  const WelcomeScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.3),
          radius: 1.15,
          colors: [Color(0xFF07515A), Color(0xFF071A2B), VColors.background],
        ),
      ),
      child: LayoutBuilder(builder: (context, bounds) {
        final compact = bounds.maxHeight < 760;
        return Column(children: [
          Expanded(child: LayoutBuilder(builder: (context, scrollBounds) =>
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: scrollBounds.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(children: [
                      SizedBox(height: compact ? 22 : 63),
                      VeldigoLogo(size: compact ? 75 : 96, showName: false),
                      SizedBox(height: compact ? 27 : 64),
                      Text('Sve vaše lozinke.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: compact ? 25 : 29,
                          height: 1.18, fontWeight: FontWeight.w700)),
                      Text('Jedan siguran trezor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: VColors.accent,
                          fontSize: compact ? 25 : 29,
                          height: 1.18, fontWeight: FontWeight.w700)),
                      SizedBox(height: compact ? 14 : 24),
                      const Text(
                        'Spremite pristupne podatke, kartice i privatne '
                        'bilješke u preglednom i zaštićenom prostoru.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: VColors.muted,
                          fontSize: 14, height: 1.4)),
                      SizedBox(height: compact ? 20 : 36),
                      const VPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Benefit('Zaštićen lokalni trezor',
                              Icons.lock_outline),
                            SizedBox(height: 13),
                            _Benefit('Generator snažnih lozinki',
                              Icons.auto_awesome_outlined),
                            SizedBox(height: 13),
                            _Benefit('Šifrirana sigurnosna kopija',
                              Icons.sync_alt),
                          ],
                        ),
                      ),
                    ]),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 24, 0, 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fiber_manual_record,
                            size: 15, color: VColors.accent),
                          Icon(Icons.fiber_manual_record,
                            size: 10, color: VColors.muted),
                          Icon(Icons.fiber_manual_record,
                            size: 10, color: VColors.muted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
            child: Column(children: [
              SizedBox(width: double.infinity,
                child: VPrimaryButton(label: 'Započni',
                  icon: Icons.arrow_forward, onPressed: onStart)),
              TextButton(
                onPressed: onStart,
                child: const Text('Već imate trezor? Uvezite kopiju',
                  style: TextStyle(color: VColors.muted, fontSize: 12))),
            ]),
          ),
        ]);
      }),
    )),
  );
}

class _Benefit extends StatelessWidget {
  final String title;
  final IconData icon;
  const _Benefit(this.title, this.icon);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: VColors.accent, size: 20),
    const SizedBox(width: 12),
    Expanded(child: Text(title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
  ]);
}
