import 'package:flutter/material.dart';

abstract final class VColors {
  // These are design tokens measured against the reference's dark navy
  // cards and cyan-green accents, shared by every Android/Windows screen.
  static const background = Color(0xFF051321);
  static const surface = Color(0xFF091C2D);
  static const raised = Color(0xFF0D293B);
  static const border = Color(0xFF15364A);
  static const accent = Color(0xFF22DCD4);
  static const text = Color(0xFFF3FAFF);
  static const muted = Color(0xFF92A9BF);
  static const red = Color(0xFFFF6479);
  static const warning = Color(0xFFFFB34F);
  static const blue = Color(0xFF66B6FF);
  static const success = Color(0xFF36D6A9);
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
      appBarTheme: const AppBarTheme(
        backgroundColor: VColors.background,
        foregroundColor: VColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VColors.background,
        elevation: 0,
        indicatorColor: VColors.raised,
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          TextStyle(
            color: states.contains(WidgetState.selected)
                ? VColors.accent : VColors.muted,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700 : FontWeight.w500,
          )),
        iconTheme: WidgetStateProperty.resolveWith((states) =>
          IconThemeData(
            color: states.contains(WidgetState.selected)
                ? VColors.accent : VColors.muted,
            size: 23,
          )),
      ),
      dividerColor: VColors.border,
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
    // The supplied Veldigo emblem has a soft teal halo behind a crisp
    // shield outline. Paint the glow first to preserve sharp 1px edges.
    canvas.drawPath(p, Paint()
      ..color = VColors.accent.withValues(alpha: .26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .09
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * .075));
    canvas.drawPath(p, Paint()..color = VColors.accent
      ..style = PaintingStyle.stroke..strokeWidth = size.width * .066
      ..strokeJoin = StrokeJoin.round);
    final v = Path()..moveTo(size.width * .32, size.height * .32)
      ..lineTo(size.width * .5, size.height * .69)
      ..lineTo(size.width * .7, size.height * .32);
    canvas.drawPath(v, Paint()
      ..color = VColors.accent.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * .06));
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
  Widget build(BuildContext context) => Material(
    color: VColors.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: VColors.border),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class VPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const VPrimaryButton({super.key, required this.label, this.onPressed, this.icon});
  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: Colors.transparent,
      disabledBackgroundColor: Colors.transparent,
      foregroundColor: VColors.background,
      disabledForegroundColor: VColors.muted,
      shadowColor: Colors.transparent,
      minimumSize: const Size(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .1),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: onPressed == null ? VColors.raised : null,
        gradient: onPressed == null ? null : const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF11CDBF), Color(0xFF4AEBD8)],
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: icon == null
          ? FilledButton(style: style, onPressed: onPressed, child: Text(label))
          : FilledButton.icon(
              style: style,
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
            ),
    );
  }
}

/// Consistent reference-inspired heading for secondary Android and desktop
/// pages; the layout contracts, rather than text scale, control responsiveness.
class VSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const VSectionHeader({super.key, required this.title, this.subtitle,
    this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 2, 0, 16),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22,
              fontWeight: FontWeight.w800, color: VColors.text)),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(subtitle!, style: const TextStyle(
              fontSize: 12, color: VColors.muted, height: 1.35)),
          ],
        ])),
      if (trailing != null) ...[
        const SizedBox(width: 10),
        trailing!,
      ],
    ]),
  );
}

class VCategoryPill extends StatelessWidget {
  final String name;
  const VCategoryPill({super.key, required this.name});
  @override
  Widget build(BuildContext context) {
    final lower = name.toLowerCase();
    final color = lower.contains('posao') || lower.contains('work')
        ? VColors.blue : lower.contains('zabava')
        ? const Color(0xFFB693FF) : lower.contains('financ')
        ? VColors.warning : VColors.accent;
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        border: Border.all(color: color.withValues(alpha: .22)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 10,
          fontWeight: FontWeight.w600)),
    );
  }
}
