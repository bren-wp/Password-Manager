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
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: VColors.accent,
        brightness: Brightness.dark,
        surface: VColors.surface,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 24, height: 1.17,
          letterSpacing: -.45, fontWeight: FontWeight.w800, color: VColors.text),
        headlineSmall: TextStyle(fontSize: 21, height: 1.2,
          letterSpacing: -.25, fontWeight: FontWeight.w800, color: VColors.text),
        titleLarge: TextStyle(fontSize: 19, height: 1.24,
          fontWeight: FontWeight.w700, color: VColors.text),
        titleMedium: TextStyle(fontSize: 15, height: 1.3,
          fontWeight: FontWeight.w700, color: VColors.text),
        bodyLarge: TextStyle(fontSize: 15, height: 1.45, color: VColors.text),
        bodyMedium: TextStyle(fontSize: 13, height: 1.4, color: VColors.text),
        bodySmall: TextStyle(fontSize: 11, height: 1.35, color: VColors.muted),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: VColors.text),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: VColors.background,
        foregroundColor: VColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
        titleTextStyle: TextStyle(fontFamily: 'Roboto',
          color: VColors.text, fontSize: 16, fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: VColors.accent, size: 21),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(
        foregroundColor: VColors.muted,
        iconSize: 20,
        minimumSize: const Size(44, 44),
      )),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: VColors.accent,
        selectionColor: Color(0x5522DCD4),
        selectionHandleColor: VColors.accent),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: VColors.accent,
        side: const BorderSide(color: VColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        minimumSize: const Size(0, 44),
        textStyle: const TextStyle(
          fontFamily: 'Roboto', fontWeight: FontWeight.w700),
      )),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: VColors.raised,
        contentTextStyle: TextStyle(
          fontFamily: 'Roboto', color: VColors.text, fontSize: 13),
        behavior: SnackBarBehavior.floating),
      dividerTheme: const DividerThemeData(
        color: VColors.border, thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(
        dense: true,
        minVerticalPadding: 7,
        minLeadingWidth: 24,
        horizontalTitleGap: 12,
        iconColor: VColors.accent,
        textColor: VColors.text,
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VColors.background,
        elevation: 0,
        indicatorColor: VColors.raised,
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          TextStyle(fontFamily: 'Roboto',
            color: states.contains(WidgetState.selected)
                ? VColors.accent : VColors.muted,
            fontSize: 10,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700 : FontWeight.w500,
          )),
        iconTheme: WidgetStateProperty.resolveWith((states) =>
          IconThemeData(
            color: states.contains(WidgetState.selected)
                ? VColors.accent : VColors.muted,
            size: 21,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      cardTheme: CardThemeData(
        color: VColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
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
    final width = size.width;
    final height = size.height;
    final bounds = Offset.zero & size;

    // Trace the user's shield reference with a rounded, pointed silhouette
    // instead of the older angular polygon. Keep this path vector-based so
    // one genuine brand mark remains sharp on high-DPI Android and Windows.
    final shield = Path()
      ..moveTo(width * .5, height * .045)
      ..cubicTo(width * .62, height * .107,
          width * .77, height * .154,
          width * .903, height * .18)
      ..lineTo(width * .91, height * .48)
      ..cubicTo(width * .905, height * .70,
          width * .74, height * .85,
          width * .5, height * .965)
      ..cubicTo(width * .26, height * .85,
          width * .095, height * .70,
          width * .09, height * .48)
      ..lineTo(width * .097, height * .18)
      ..cubicTo(width * .23, height * .154,
          width * .38, height * .107,
          width * .5, height * .045)
      ..close();

    canvas.drawPath(shield, Paint()
      ..color = VColors.accent.withValues(alpha: .12)
      ..style = PaintingStyle.fill);
    canvas.drawPath(shield, Paint()
      ..color = VColors.accent.withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * .068
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * .045));
    canvas.drawPath(shield, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * .052
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF75FFF2), VColors.accent, Color(0xFF08BDAF)],
      ).createShader(bounds));

    // The reference has a filled, bevelled V rather than a stroked letter.
    // Two joined vector facets retain their detail at small app-icon sizes.
    final leftFacet = Path()
      ..moveTo(width * .235, height * .32)
      ..lineTo(width * .39, height * .32)
      ..lineTo(width * .50, height * .607)
      ..lineTo(width * .50, height * .786)
      ..quadraticBezierTo(width * .46, height * .782,
          width * .432, height * .721)
      ..close();
    final rightFacet = Path()
      ..moveTo(width * .50, height * .607)
      ..lineTo(width * .622, height * .32)
      ..lineTo(width * .778, height * .32)
      ..lineTo(width * .565, height * .728)
      ..quadraticBezierTo(width * .53, height * .788,
          width * .50, height * .786)
      ..close();
    final emblem = Path.combine(
      PathOperation.union, leftFacet, rightFacet);
    canvas.drawPath(emblem, Paint()
      ..color = VColors.accent.withValues(alpha: .4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * .027));
    canvas.drawPath(leftFacet, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF81FFEE), Color(0xFF09DCCB)],
      ).createShader(bounds));
    canvas.drawPath(rightFacet, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF20EBDB), Color(0xFF009A9F)],
      ).createShader(bounds));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const VPanel({super.key, required this.child,
    this.padding = const EdgeInsets.all(15)});
  @override
  Widget build(BuildContext context) => Material(
    color: VColors.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
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
      textStyle: const TextStyle(fontFamily: 'Roboto',
        fontWeight: FontWeight.w800, letterSpacing: .1),
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
    padding: const EdgeInsets.fromLTRB(0, 2, 0, 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 21, height: 1.18,
              letterSpacing: -.25, fontWeight: FontWeight.w800,
              color: VColors.text)),
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
