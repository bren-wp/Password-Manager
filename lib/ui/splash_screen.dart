import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand.dart';

/// The first frame of Veldigo. This screen never opens or reads vault data.
///
/// The live startup uses an *indeterminate* loading bar because vault startup
/// has no reliable fractional progress. An explicit progress value is allowed
/// only for deterministic design previews and widget screenshot captures.
class SplashScreen extends StatelessWidget {
  final double? progress;
  const SplashScreen({super.key, this.progress});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.28),
          radius: 1.05,
          colors: [
            Color(0xFF075059),
            Color(0xFF062536),
            VColors.background,
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(builder: (context, bounds) {
          final compact = bounds.maxHeight < 690;
          final logoSize = math.min(102.0,
              math.max(72.0, bounds.maxWidth * .245));
          final headingSize = bounds.maxWidth < 360 ? 32.0 : 37.0;
          return Column(children: [
            Expanded(
              child: LayoutBuilder(builder: (context, heroBounds) =>
                SingleChildScrollView(
                  key: const ValueKey('veldigo-splash-hero-scroll'),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: heroBounds.maxHeight),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Transform.translate(
                          offset: Offset(0, compact ? -8 : -20),
                          child: Column(
                            key: const ValueKey('veldigo-splash-hero'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Semantics(
                                image: true,
                                label: 'Logotip Veldigo',
                                child: ExcludeSemantics(
                                  child: VeldigoLogo(
                                    size: logoSize, showName: false),
                                ),
                              ),
                              SizedBox(height: compact ? 14 : 20),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('VELDIGO',
                                  style: TextStyle(
                                    fontSize: headingSize,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 6,
                                    color: VColors.text,
                                  )),
                              ),
                              const SizedBox(height: 8),
                              const Text('PASSWORD MANAGER',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 2.4,
                                  color: VColors.muted,
                                )),
                              SizedBox(height: compact ? 26 : 45),
                              const Text('Vaše lozinke.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18, color: VColors.text)),
                              const SizedBox(height: 5),
                              const Text('Uvijek sigurne.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: VColors.accent,
                                )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: compact ? 24 : 47,
                left: 16,
                right: 16,
              ),
              child: Semantics(
                label: 'Pokretanje aplikacije Veldigo',
                child: Column(
                  key: const ValueKey('veldigo-splash-footer'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 3,
                      child: LinearProgressIndicator(
                        key: const ValueKey('veldigo-splash-progress'),
                        value: progress,
                        backgroundColor: VColors.border,
                        color: VColors.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('VAŠ DIGITALNI TREZOR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: VColors.muted,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      )),
                  ],
                ),
              ),
            ),
          ]);
        }),
      ),
    ),
  );
}
