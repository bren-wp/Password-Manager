import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/splash_screen.dart';
import 'package:veldigo/ui/welcome_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first-run screen keeps independent create and import actions',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in <Size>[
      const Size(320, 640),
      const Size(393, 852),
      const Size(480, 900),
      const Size(1200, 800),
    ]) {
      tester.view.physicalSize = size;
      var starts = 0;
      var imports = 0;

      await tester.pumpWidget(MaterialApp(
        theme: veldigoTheme(),
        home: WelcomeScreen(
          onStart: () => starts++,
          onImport: () => imports++,
        ),
      ));
      await tester.pumpAndSettle();

      final start = find.text('Započni');
      final importAction = find.text('Već imate trezor? Uvezite kopiju');
      expect(start, findsOneWidget);
      expect(importAction, findsOneWidget);
      expect(tester.getRect(start).bottom, lessThanOrEqualTo(size.height));
      expect(tester.getRect(importAction).bottom, lessThanOrEqualTo(size.height));

      await tester.tap(importAction);
      await tester.pump();
      expect(imports, 1, reason: 'Import is separate from creating a vault.');
      expect(starts, 0);
      await tester.tap(start);
      await tester.pump();
      expect(starts, 1);
      expect(imports, 1);
      expect(tester.takeException(), isNull);

      final panels = find.byType(VPanel);
      expect(panels, findsOneWidget);
      expect(tester.getSize(panels).width, lessThanOrEqualTo(480),
          reason: 'Welcome cards must not span a desktop-sized window.');
    }
  });

  testWidgets('splash retains nonoverlapping logo and footer at mobile sizes',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in <Size>[
      const Size(320, 640),
      const Size(393, 852),
      const Size(480, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(MaterialApp(
        theme: veldigoTheme(),
        home: const SplashScreen(),
      ));
      await tester.pump();

      final logo = tester.getRect(find.byType(VeldigoLogo));
      final footer = tester.getRect(find.text('VAŠ DIGITALNI TREZOR'));
      expect(footer.top, greaterThan(logo.bottom));
      expect(footer.bottom, lessThanOrEqualTo(size.height));
      expect(tester.takeException(), isNull);
    }
  });
}
