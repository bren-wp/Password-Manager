import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/password_generator.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/extra_pages.dart';

void main() {
  test('similar-character exclusion preserves the previous secure defaults', () {
    final oldStyle = PasswordGenerator.generate(length: 128);
    expect(oldStyle.length, 128);
    expect(oldStyle.contains(RegExp(r'[01Il]')), isFalse);

    final expanded = List.generate(32, (_) =>
        PasswordGenerator.generate(length: 128, avoidSimilar: false)).join();
    expect(expanded.contains(RegExp(r'[01Il]')), isTrue);
  });

  testWidgets('generator option updates the real setting, not a mock toggle',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: const Scaffold(body: GeneratorPage()),
    ));
    await tester.pumpAndSettle();
    final switchFinder =
        find.widgetWithText(SwitchListTile, 'Izbjegni slične znakove');
    await tester.ensureVisible(switchFinder);
    expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
    await tester.tap(find.text('Izbjegni slične znakove'));
    await tester.pump();
    expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);
    expect(tester.widget<Slider>(find.byType(Slider)).max, 128);
    expect(tester.takeException(), isNull);
  });
}
