import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_store.dart';
import 'package:veldigo/ui/auth_screen.dart';
import 'package:veldigo/ui/brand.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android setup and unlock keep primary actions reachable',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    final store = VaultStore(vaultFileOverride:
        File('${Directory.systemTemp.path}/veldigo-auth-layout-unused'));
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
            key: ValueKey('auth-$size-$create'),
            store: store,
            create: create,
          ),
        ));
        await tester.pumpAndSettle();
        final action = find.text(
            create ? 'Stvori sigurni trezor' : 'Otključaj trezor');
        expect(action, findsOneWidget);
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        final rect = tester.getRect(action);
        expect(rect.top, greaterThanOrEqualTo(0),
          reason: 'The primary action must be reachable at $size.');
        expect(rect.bottom, lessThanOrEqualTo(size.height),
          reason: 'The primary action must stay in the viewport at $size.');
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('forgotten-password help never suggests a password reset',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    final store = VaultStore(vaultFileOverride:
        File('${Directory.systemTemp.path}/veldigo-help-unused'));
    addTearDown(store.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: AuthScreen(store: store, create: false),
    ));
    final help = find.text('Zaboravili ste lozinku?');
    await tester.ensureVisible(help);
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(find.textContaining('Glavnu lozinku nije moguće'),
        findsOneWidget);
    expect(find.text('Razumijem'), findsOneWidget);
    await tester.tap(find.text('Razumijem'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Windows split auth has genuine security feature rows',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    final store = VaultStore(vaultFileOverride:
        File('${Directory.systemTemp.path}/veldigo-desktop-layout-unused'));
    addTearDown(store.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: AuthScreen(store: store, create: false),
    ));
    await tester.pumpAndSettle();
    for (final name in [
      'Sigurno spremanje', 'Potpuna privatnost', 'Uvijek dostupno',
      'Otključaj trezor',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Koristi Windows Hello'), findsNothing,
      reason: 'Do not advertise a nonfunctional security bypass.');
    expect(tester.takeException(), isNull);
  });
}
