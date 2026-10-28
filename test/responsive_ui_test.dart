import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/vault_shell.dart';
import 'package:veldigo/ui/welcome_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('welcome page adapts to narrow and tall phones', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in <Size>[
      const Size(320, 640),
      const Size(393, 852),
      const Size(600, 960),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(MaterialApp(
        theme: veldigoTheme(),
        home: WelcomeScreen(onStart: () {}),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Jedan siguran trezor.'), findsOneWidget);
      expect(find.text('Započni'), findsOneWidget);
    }
  });

  testWidgets('vault adapts across Android and Windows width ranges',
      (tester) async {
    // Filesystem and Argon2 computations need real async time; Flutter
    // widget tests otherwise run in FakeAsync and may never complete.
    final prepared = await tester.runAsync(() async {
      final temp = await Directory.systemTemp.createTemp('veldigo-ui-');
      final store = VaultStore(vaultFileOverride: File('${temp.path}/vault'));
      await store.initialize();
      await store.create('a very long test-only master phrase');
      await store.put(VaultItem(
        id: 'test-account',
        kind: ItemKind.password,
        title: 'GitHub',
        username: 'tester@example.test',
        secret: 'test-only-secret',
        updatedAt: DateTime.utc(2026, 10, 28),
      ));
      return (temp: temp, store: store);
    });
    if (prepared == null) {
      throw StateError('Trezor za test nije inicijaliziran.');
    }
    final temp = prepared.temp;
    final store = prepared.store;
    addTearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in <Size>[
      const Size(320, 640),
      const Size(393, 852),
      const Size(820, 560),
      const Size(1200, 800),
      const Size(1600, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(MaterialApp(
        theme: veldigoTheme(),
        home: VaultShell(store: store),
      ));
      await tester.pumpAndSettle();
      expect(find.text('GitHub'), findsWidgets);
      // Flutter's widget tester reports RenderFlex overflow as a test failure.
    }
    store.lock();
  }, timeout: const Timeout(Duration(minutes: 4)));
}
