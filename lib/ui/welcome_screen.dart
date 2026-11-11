import 'package:flutter/material.dart';

import 'brand.dart';

/// The first-run introduction retains both actions within the viewport,
/// including on 320x640 phones and when Android changes the font scale.
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback? onImport;
  const WelcomeScreen({super.key, required this.onStart, this.onImport});

  @override
  Widget build(BuildContext context) => Scaffold(
    // Paint the gradient beneath the system insets, like the splash screen.
    // Keep controls inside SafeArea and the content bounded on wide displays.
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        // The owner-supplied Splash and Welcome PNGs share a common
        // navy/turquoise backdrop. Reuse the measured Splash gradient.
        gradient: RadialGradient(
          center: Alignment(0, -.342),
          radius: 1.512,
          colors: [
            Color(0xFF093A4C),
            Color(0xFF061525),
            Color(0xFF04101E),
          ],
        ),
      ),
      child: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: LayoutBuilder(builder: (context, bounds) {
        final compact = bounds.maxHeight < 760;
        return Column(children: [
          Expanded(child: LayoutBuilder(builder: (context, scrollBounds) =>
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: scrollBounds.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(children: [
                      SizedBox(height: compact ? 22 : 115),
                      Semantics(
                        image: true,
                        label: 'Veldigo štit',
                        child: ExcludeSemantics(
                          child: VeldigoLogo(
                            size: compact ? 75 : 112,
                            showName: false,
                            flatReference: true,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 27 : 64),
                      Text('Sve vaše lozinke.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: compact ? 25 : 31,
                          height: 1.18, fontWeight: FontWeight.w700)),
                      Text('Jedan siguran trezor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: VColors.accent,
                          fontSize: compact ? 25 : 29,
                          height: 1.18, fontWeight: FontWeight.w700)),
                      SizedBox(height: compact ? 14 : 16),
                      const Text(
                        'Spremite pristupne podatke, kartice i privatne '
                        'bilješke u preglednom i zaštićenom prostoru.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: VColors.muted,
                          fontSize: 14, height: 1.4)),
                      SizedBox(height: compact ? 20 : 40),
                      const VPanel(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18, vertical: 18),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 24, 0, 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            key: const ValueKey('veldigo-welcome-page-indicator'),
                            width: 22, height: 7,
                            decoration: BoxDecoration(
                              color: VColors.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Icon(Icons.circle,
                            size: 7, color: Color(0xFF3B5D74)),
                          const SizedBox(width: 7),
                          const Icon(Icons.circle,
                            size: 7, color: Color(0xFF3B5D74)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, compact ? 12 : 29),
            child: Column(children: [
              SizedBox(width: double.infinity, height: 47,
                child: VPrimaryButton(
                  label: 'Započni',
                  icon: Icons.arrow_forward,
                  iconOnRight: true,
                  onPressed: onStart,
                )),
              TextButton(
                onPressed: onImport ?? onStart,
                child: const Text.rich(TextSpan(children: [
                  TextSpan(text: 'Već imate trezor?',
                    style: TextStyle(color: VColors.muted)),
                  TextSpan(text: ' Uvezite kopiju',
                    style: TextStyle(color: VColors.accent)),
                ]), style: TextStyle(fontSize: 12)),
              ),
            ]),
          ),
        ]);
        }),
      ))),
    ),
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
