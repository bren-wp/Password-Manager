import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/welcome_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android Welcome source geometry at 416x928 logical pixels',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(416, 928);

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

    final shield = tester.getRect(find.byType(VeldigoLogo));
    final panel = tester.getRect(find.byType(VPanel));
    final progress = tester.getRect(
      find.byKey(const ValueKey('veldigo-welcome-page-indicator')));
    final action = tester.getRect(find.text('Započni'));
    final arrow = tester.getRect(find.byIcon(Icons.arrow_forward));

    // Reference is 832x1856 physical pixels at 2x DPR. Compare equivalent
    // logical coordinates with a measured tolerance for font rasterization.
    expect(shield.top, inInclusiveRange(105, 130));
    expect(shield.width, 112);
    expect(panel.left, inInclusiveRange(18, 22));
    expect(panel.right, inInclusiveRange(394, 398));
    expect(panel.top, inInclusiveRange(435, 488));
    expect(progress.top, inInclusiveRange(745, 795));
    expect(progress.width, 22);
    expect(progress.height, 7);
    expect(action.top, inInclusiveRange(780, 846));
    expect(arrow.left, greaterThan(action.right),
      reason: 'The source CTA arrow sits AFTER its label.');
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Već imate trezor? Uvezite kopiju'));
    await tester.pump();
    expect(imports, 1);
    expect(starts, 0);
    await tester.tap(find.text('Započni'));
    await tester.pump();
    expect(starts, 1);
    expect(imports, 1);
  });

  testWidgets('Android Welcome stays accessible at short viewports and zoom',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in <Size>[
      const Size(320, 640),
      const Size(393, 852),
      const Size(480, 900),
      const Size(600, 960),
    ]) {
      for (final scale in <double>[1.0, 1.5]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(MaterialApp(
          key: ValueKey('welcome-$size-$scale'),
          theme: veldigoTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: WelcomeScreen(
            onStart: () {},
            onImport: () {},
          ),
        ));
        await tester.pumpAndSettle();

        final start = find.text('Započni');
        final importAction = find.text('Već imate trezor? Uvezite kopiju');
        expect(start, findsOneWidget);
        expect(importAction, findsOneWidget);
        await tester.ensureVisible(start);
        await tester.ensureVisible(importAction);
        await tester.pumpAndSettle();
        expect(tester.getRect(start).bottom,
            lessThanOrEqualTo(size.height));
        expect(tester.getRect(importAction).bottom,
            lessThanOrEqualTo(size.height));
        expect(tester.takeException(), isNull,
          reason: 'Welcome overflow at $size with scale $scale');
      }
    }
  });
}
