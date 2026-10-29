import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/extra_pages.dart';

void main() {
  testWidgets('generator instantly regenerates on length and charset changes',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: const Scaffold(body: GeneratorPage()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Generator lozinki'), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 20);
    await tester.ensureVisible(find.text('Posebni znakovi'));
    await tester.tap(find.text('Posebni znakovi'));
    await tester.pump();
    expect(tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Posebni znakovi')).value, isFalse);

    await tester.drag(find.byType(Slider), const Offset(40, 0));
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider)).value,
      greaterThan(20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('all generator character groups cannot be switched off',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: const Scaffold(body: GeneratorPage()),
    ));
    await tester.pumpAndSettle();
    for (final label in ['Velika slova (A–Z)', 'Mala slova (a–z)',
        'Brojevi (0–9)']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pump();
    }
    await tester.tap(find.text('Posebni znakovi'));
    await tester.pump();
    expect(tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Posebni znakovi')).value, isTrue);
    expect(find.text('Najmanje jedna skupina znakova mora ostati uključena.'),
      findsOneWidget);
  });

  testWidgets('security center does not claim 100/100 for empty vault',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: const Scaffold(body: SecurityPage(items: [])),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Sigurnosni centar'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(find.text('100'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
