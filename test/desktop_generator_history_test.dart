import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/extra_pages.dart';

void main() {
  testWidgets('Windows generator history is functional and masked',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: const Scaffold(body: GeneratorPage()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Povijest generiranih lozinki'), findsOneWidget);
    expect(find.text('Povijest je prazna. Generirajte novu lozinku.'),
        findsOneWidget);

    final firstPassword = tester.widget<SelectableText>(
        find.byType(SelectableText).first).data!;
    await tester.tap(find.text('Generiraj novu lozinku'));
    await tester.pumpAndSettle();
    expect(find.text(firstPassword), findsNothing,
        reason: 'Historical passwords must not appear unmasked.');
    expect(find.byTooltip('Kopiraj lozinku iz povijesti'), findsOneWidget);

    await tester.tap(find.text('Generiraj novu lozinku'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Kopiraj lozinku iz povijesti'), findsNWidgets(2));

    await tester.ensureVisible(find.text('Očisti povijest'));
    await tester.tap(find.text('Očisti povijest'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Kopiraj lozinku iz povijesti'), findsNothing);
    expect(find.text('Povijest je prazna. Generirajte novu lozinku.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile generator retains Android switches, without history',
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
    expect(find.byType(SwitchListTile), findsWidgets);
    expect(find.text('Povijest generiranih lozinki'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
