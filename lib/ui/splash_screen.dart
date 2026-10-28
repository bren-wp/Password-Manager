import 'package:flutter/material.dart';

import 'brand.dart';

/// Visible while the encrypted vault metadata is initializing.
/// Shares the Veldigo design system with Android and Windows.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.15),
          radius: 1.0,
          colors: [Color(0xFF07545A), Color(0xFF092334),
            VColors.background],
        ),
      ),
      child: SafeArea(child: Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VeldigoLogo(size: 108, showName: false),
          const SizedBox(height: 32),
          const Text('VELDIGO', style: TextStyle(
            fontSize: 34, letterSpacing: 6, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const Text('VAŠE LOZINKE. VAŠA KONTROLA.',
            style: TextStyle(color: VColors.muted,
              fontSize: 11, letterSpacing: 1.9)),
          const SizedBox(height: 48),
          SizedBox(width: 26, height: 26, child: CircularProgressIndicator(
            strokeWidth: 2, color: VColors.accent.withValues(alpha: .8))),
        ],
      ))),
    ),
  );
}
