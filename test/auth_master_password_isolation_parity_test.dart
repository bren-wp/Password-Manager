import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_store.dart';
import 'package:veldigo/ui/auth_screen.dart';
import 'package:veldigo/ui/brand.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  VaultStore unusedStore(String suffix) => VaultStore(
    vaultFileOverride: File(
      '${Directory.systemTemp.path}/veldigo-auth-parity-$suffix-unused'),
  );

  testWidgets('Showing master password never reveals its confirmation',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    final store = unusedStore('independent');
    addTearDown(store.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: AuthScreen(store: store, create: true),
    ));
    await tester.pumpAndSettle();

    const masterKey = ValueKey('veldigo-master-password-field');
    const confirmKey = ValueKey('veldigo-confirm-password-field');
    TextField secureInput(ValueKey key) => tester.widget<TextField>(
      find.descendant(
        of: find.byKey(key),
        matching: find.byType(TextField),
      ),
    );

    expect(secureInput(masterKey).obscureText, isTrue);
    expect(secureInput(confirmKey).obscureText, isTrue);
    expect(secureInput(masterKey).enableIMEPersonalizedLearning, isFalse);
    expect(secureInput(confirmKey).enableIMEPersonalizedLearning, isFalse);

    await tester.tap(find.byTooltip('Prikaži'));
    await tester.pump();
    expect(secureInput(masterKey).obscureText, isFalse);
    expect(secureInput(confirmKey).obscureText, isTrue,
      reason: 'Master visibility must not expose confirmation.');

    await tester.tap(find.byTooltip('Prikaži potvrdu'));
    await tester.pump();
    expect(secureInput(confirmKey).obscureText, isFalse);

    await tester.tap(find.byTooltip('Sakrij'));
    await tester.pump();
    expect(secureInput(masterKey).obscureText, isTrue);
    expect(secureInput(confirmKey).obscureText, isFalse,
      reason: 'Visibility controls must stay independent.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back from setup is real and does not create a vault',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    final store = unusedStore('back');
    addTearDown(store.dispose);
    var backCount = 0;
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: AuthScreen(
        store: store,
        create: true,
        onBack: () => backCount++,
      ),
    ));
    await tester.pumpAndSettle();

    final back = find.byTooltip('Natrag na dobrodošlicu');
    expect(back, findsOneWidget);
    await tester.tap(back);
    await tester.pump();
    expect(backCount, 1);
    expect(store.hasVault, isFalse);
    expect(store.isUnlocked, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Creation validates minimum 12 characters and confirmation',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    final store = unusedStore('validation');
    addTearDown(store.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: AuthScreen(store: store, create: true),
    ));
    await tester.pumpAndSettle();

    const masterKey = ValueKey('veldigo-master-password-field');
    const confirmKey = ValueKey('veldigo-confirm-password-field');
    final action = find.text('Stvori sigurni trezor');
    await tester.enterText(find.byKey(masterKey), 'Kratka123');
    await tester.enterText(find.byKey(confirmKey), 'Kratka123');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pump();
    expect(find.text('Koristite najmanje 12 znakova.'), findsOneWidget);
    expect(store.hasVault, isFalse);

    await tester.enterText(find.byKey(masterKey), 'Dugacka-Lozinka-123!');
    await tester.enterText(find.byKey(confirmKey), 'Kriva-Lozinka-12345!');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pump();
    expect(find.text('Lozinke se ne podudaraju.'), findsOneWidget);
    expect(store.hasVault, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Auth screens remain scrollable at small Android sizes',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    final store = unusedStore('viewport');
    addTearDown(store.dispose);

    for (final size in <Size>[
      const Size(320, 640),
      const Size(393, 852),
      const Size(480, 900),
    ]) {
      for (final create in <bool>[true, false]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(MaterialApp(
          theme: veldigoTheme(),
          home: AuthScreen(
            key: ValueKey('auth-view-$size-$create'),
            store: store,
            create: create,
          ),
        ));
        await tester.pumpAndSettle();
        final action = find.text(create
            ? 'Stvori sigurni trezor' : 'Otključaj trezor');
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        final r = tester.getRect(action);
        expect(r.bottom, lessThanOrEqualTo(size.height));
        expect(r.top, greaterThanOrEqualTo(0));
        expect(tester.takeException(), isNull,
          reason: 'Auth overflow or inaccessible primary action at $size');
      }
    }
  });
}
