import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_store.dart';
import 'package:veldigo/ui/auth_screen.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/extra_pages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android generator uses five equal reference meter segments',
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

    expect(find.byKey(const ValueKey('veldigo-strength-segments')),
        findsOneWidget);
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(ValueKey('veldigo-strength-segment-$i')),
          findsOneWidget);
    }
    expect(find.byType(LinearProgressIndicator), findsNothing,
        reason: 'Reference uses five separate strength segments.');
    expect(find.text('Velika slova (A–Z)'), findsOneWidget);
    expect(find.text('Izbjegni slične znakove'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary generator action stays visible above Android nav',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    // Cover compact and full-size Android viewports with a 72px nav bar.
    for (final size in <Size>[
      const Size(320, 640),
      const Size(393, 852),
      const Size(480, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(MaterialApp(
        theme: veldigoTheme(),
        home: const Scaffold(
          body: GeneratorPage(),
          bottomNavigationBar: SizedBox(height: 72),
        ),
      ));
      await tester.pumpAndSettle();
      final button = find.text('Generiraj novu lozinku');
      expect(button, findsOneWidget);
      final position = tester.getRect(button);
      expect(position.bottom, lessThanOrEqualTo(size.height - 72),
          reason: 'The generator action must stay above navigation at $size.');
      expect(position.left, greaterThanOrEqualTo(0));
      expect(position.right, lessThanOrEqualTo(size.width));
      await tester.tap(button);
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: 'The visible primary action must work at $size.');
    }
  });

  testWidgets('Windows generator shares the five-segment meter',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: const Scaffold(body: GeneratorPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('veldigo-strength-segments')),
        findsOneWidget);
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(ValueKey('veldigo-strength-segment-$i')),
          findsOneWidget);
    }
    expect(find.text('Povijest generiranih lozinki'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('master password inputs never enable keyboard learning',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;

    final store = VaultStore(vaultFileOverride: File(
        '${Directory.systemTemp.path}/veldigo-auth-input-privacy-unused'));
    addTearDown(store.dispose);

    for (final create in [true, false]) {
      await tester.pumpWidget(MaterialApp(
        theme: veldigoTheme(),
        home: AuthScreen(
          key: ValueKey(create ? 'create-private' : 'unlock-private'),
          store: store,
          create: create,
        ),
      ));
      await tester.pumpAndSettle();
      for (final input in tester.widgetList<TextField>(find.byType(TextField))) {
        expect(input.enableIMEPersonalizedLearning, isFalse);
        expect(input.smartDashesType, SmartDashesType.disabled);
        expect(input.smartQuotesType, SmartQuotesType.disabled);
        expect(input.autocorrect, isFalse);
        expect(input.enableSuggestions, isFalse);
      }
      expect(tester.takeException(), isNull);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
