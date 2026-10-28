import 'package:flutter/material.dart';

abstract final class VColors {
  static const background = Color(0xFF05111F);
  static const surface = Color(0xFF0A1C2F);
  static const raised = Color(0xFF10253A);
  static const border = Color(0xFF1E3C52);
  static const accent = Color(0xFF27E4D2);
  static const text = Color(0xFFF4F8FF);
  static const muted = Color(0xFF91A9C4);
  static const red = Color(0xFFFF6677);
}

ThemeData veldigoTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: VColors.accent,
        brightness: Brightness.dark,
        surface: VColors.surface,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: VColors.text),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: VColors.text),
        bodyMedium: TextStyle(color: VColors.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VColors.surface,
        hintStyle: const TextStyle(color: VColors.muted),
        labelStyle: const TextStyle(color: VColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: VColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: VColors.border),
        ),
      ),
    );

class VeldigoLogo extends StatelessWidget {
  final double size;
  final bool showName;
  const VeldigoLogo({super.key, this.size = 56, this.showName = true});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: size, height: size, child: CustomPaint(painter: _ShieldPainter())),
      if (showName) ...[
        const SizedBox(width: 12),
        Text('VELDIGO', style: TextStyle(
          fontSize: size * .38, letterSpacing: 3.4,
          fontWeight: FontWeight.w800, color: VColors.text)),
      ],
    ]);
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width * .5, size.height * .05)
      ..lineTo(size.width * .9, size.height * .21)
      ..lineTo(size.width * .84, size.height * .65)
      ..quadraticBezierTo(size.width * .75, size.height * .86,
          size.width * .5, size.height * .97)
      ..quadraticBezierTo(size.width * .25, size.height * .86,
          size.width * .16, size.height * .65)
      ..lineTo(size.width * .1, size.height * .21)
      ..close();
    canvas.drawPath(p, Paint()..color = VColors.accent
      ..style = PaintingStyle.stroke..strokeWidth = size.width * .066
      ..strokeJoin = StrokeJoin.round);
    final v = Path()..moveTo(size.width * .32, size.height * .32)
      ..lineTo(size.width * .5, size.height * .69)
      ..lineTo(size.width * .7, size.height * .32);
    canvas.drawPath(v, Paint()..color = VColors.accent
      ..style = PaintingStyle.stroke..strokeWidth = size.width * .09
      ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const VPanel({super.key, required this.child,
    this.padding = const EdgeInsets.all(18)});
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: VColors.surface,
      border: Border.all(color: VColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}

class VPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const VPrimaryButton({super.key, required this.label, this.onPressed, this.icon});
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    style: FilledButton.styleFrom(
      backgroundColor: VColors.accent,
      foregroundColor: VColors.background,
      minimumSize: const Size(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
    onPressed: onPressed,
    icon: Icon(icon ?? Icons.lock_outline),
    label: Text(label),
  );
}
