import 'package:flutter/material.dart';

import 'brand.dart';

/// First-launch welcome page based on Veldigo's Android reference screen.
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;
  const WelcomeScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -.3),
                radius: 1.15,
                colors: [Color(0xFF07515A), Color(0xFF071A2B),
                  VColors.background],
              ),
            ),
            child: LayoutBuilder(builder: (ctx, bounds) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: bounds.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(children: [
                      SizedBox(height: bounds.maxHeight < 720 ? 24 : 65),
                      const VeldigoLogo(size: 96, showName: false),
                      SizedBox(height: bounds.maxHeight < 720 ? 40 : 64),
                      const Text('Sve vaše lozinke.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 29,
                          fontWeight: FontWeight.bold)),
                      const Text('Jedan siguran trezor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: VColors.accent,
                          fontSize: 29, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 26),
                      const Text('Spremite pristupne podatke, kartice i privatne '
                        'bilješke u preglednom i zaštićenom prostoru.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: VColors.muted,
                          fontSize: 15, height: 1.5)),
                      const SizedBox(height: 35),
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
                      SizedBox(height: bounds.maxHeight < 720
                          ? 28 : bounds.maxHeight * .095),
                      const Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fiber_manual_record,
                            size: 15, color: VColors.accent),
                          Icon(Icons.fiber_manual_record,
                            size: 10, color: VColors.muted),
                          Icon(Icons.fiber_manual_record,
                            size: 10, color: VColors.muted),
                        ]),
                      const SizedBox(height: 25),
                      SizedBox(width: double.infinity,
                        child: VPrimaryButton(
                          label: 'Započni',
                          icon: Icons.arrow_forward,
                          onPressed: onStart)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: onStart,
                        child: const Text('Već imate trezor? Uvezite kopiju',
                          style: TextStyle(color: VColors.muted))),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),
      );
}

class _Benefit extends StatelessWidget {
  final String title;
  final IconData icon;
  const _Benefit(this.title, this.icon);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: VColors.accent, size: 21),
    const SizedBox(width: 12),
    Expanded(child: Text(title,
      style: const TextStyle(fontWeight: FontWeight.w600))),
  ]);
}
