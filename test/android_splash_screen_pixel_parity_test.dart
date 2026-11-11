import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Splash keeps hero and footer in separate viewport regions',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in <Size>[
      const Size(280, 480),
      const Size(320, 568),
      const Size(320, 640),
      const Size(393, 852),
      const Size(416, 928),
      const Size(600, 960),
    ]) {
      for (final scale in <double>[1.0, 1.8]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(MaterialApp(
          key: ValueKey('splash-$size-$scale'),
          theme: veldigoTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const SplashScreen(progress: .58),
        ));
        await tester.pump();

        final viewport = tester.getRect(
            find.byKey(const ValueKey('veldigo-splash-hero-scroll')));
        final footer = tester.getRect(
            find.byKey(const ValueKey('veldigo-splash-footer')));
        expect(viewport.top, greaterThanOrEqualTo(0));
        expect(viewport.bottom, lessThanOrEqualTo(footer.top),
          reason: 'The footer must never overlay the hero viewport at '
              '$size with text scale $scale.');
        expect(footer.bottom, lessThanOrEqualTo(size.height));
        expect(footer.left, greaterThanOrEqualTo(0));
        expect(footer.right, lessThanOrEqualTo(size.width));

        expect(find.text('VELDIGO'), findsOneWidget);
        expect(find.text('PASSWORD MANAGER'), findsOneWidget);
        expect(find.text('Vaše lozinke.'), findsOneWidget);
        expect(find.text('Uvijek sigurne.'), findsOneWidget);
        expect(tester.takeException(), isNull,
          reason: 'Splash must not overflow at $size and scale $scale.');
      }
    }
  });

  testWidgets('Real splash does not advertise fabricated loading percentage',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: const SplashScreen(),
    ));
    await tester.pump();
    final loading = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('veldigo-splash-progress')));
    expect(loading.value, isNull,
      reason: 'Vault initialization has no truthful fractional progress.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screenshot splash uses a reproducible fixed preview progress',
      (tester) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: const SplashScreen(progress: .58),
    ));
    await tester.pump();
    final loading = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('veldigo-splash-progress')));
    expect(loading.value, .58);
    expect(find.bySemanticsLabel('Logotip Veldigo'), findsOneWidget);
    // Flutter merges parent/child semantics during accessibility traversal;
    // assert the configured label rather than an exact merged node string.
    expect(find.byWidgetPredicate((widget) =>
      widget is Semantics &&
      widget.properties.label == 'Pokretanje aplikacije Veldigo'),
      findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
