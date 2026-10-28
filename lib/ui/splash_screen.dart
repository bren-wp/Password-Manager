import 'package:flutter/material.dart';

import 'brand.dart';

/// Brand splash uses the reference screen's central shield/wordmark and
/// bottom progress underline. It does not draw fake OS status indicators.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
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
        child: Stack(children: [
          Align(
            alignment: const Alignment(0, -.16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VeldigoLogo(size: 102, showName: false),
                const SizedBox(height: 20),
                const Text('VELDIGO',
                  style: TextStyle(
                    fontSize: 37,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                    color: VColors.text,
                  )),
                const SizedBox(height: 8),
                const Text('PASSWORD MANAGER',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.4,
                    color: VColors.muted,
                  )),
                const SizedBox(height: 45),
                const Text('Vaše lozinke.',
                  style: TextStyle(fontSize: 18, color: VColors.text)),
                const SizedBox(height: 5),
                const Text('Uvijek sigurne.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: VColors.accent,
                  )),
              ],
            ),
          ),
          Positioned(
            bottom: 47,
            left: 0,
            right: 0,
            child: Column(children: [
              SizedBox(
                width: 100,
                height: 3,
                child: LinearProgressIndicator(
                  value: .58,
                  backgroundColor: VColors.border,
                  color: VColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 16),
              const Text('VAŠ DIGITALNI TREZOR',
                style: TextStyle(
                  color: VColors.muted,
                  fontSize: 11,
                  letterSpacing: 1.2,
                )),
            ]),
          ),
        ]),
      ),
    ),
  );
}
