import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/vault_shell.dart';

void main() {
  testWidgets('revealed account password is hidden when another account opens',
      (tester) async {
    final prepared = await tester.runAsync(() async {
      final temp = await Directory.systemTemp.createTemp('veldigo-secrecy-');
      final store = VaultStore(vaultFileOverride: File('${temp.path}/vault'));
      await store.initialize();
      await store.create('a long unique temporary test master password');
      await store.put(VaultItem(
        id: 'first', kind: ItemKind.password, title: 'First Account',
        secret: 'only-first-credential',
        updatedAt: DateTime.utc(2026, 10, 28, 12),
      ));
      await store.put(VaultItem(
        id: 'second', kind: ItemKind.password, title: 'Second Account',
        secret: 'only-second-credential',
        updatedAt: DateTime.utc(2026, 10, 28, 11),
      ));
      return (temp: temp, store: store);
    });
    if (prepared == null) throw StateError('Test trezor nije pripremljen.');
    addTearDown(() async {
      if (await prepared.temp.exists()) {
        await prepared.temp.delete(recursive: true);
      }
    });
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: VaultShell(store: prepared.store),
    ));
    await tester.pumpAndSettle();
    expect(find.text('only-first-credential'), findsNothing);
    await tester.tap(find.byTooltip('Prikaži').first);
    await tester.pump();
    expect(find.text('only-first-credential'), findsOneWidget);

    await tester.tap(find.text('Second Account').first);
    await tester.pumpAndSettle();
    expect(find.text('only-second-credential'), findsNothing);
    expect(find.byTooltip('Prikaži'), findsWidgets);
    prepared.store.lock();
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('mobile details are full-screen and clear deleted records',
      (tester) async {
    final fixture = await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('veldigo-detail-');
      final store = VaultStore(vaultFileOverride: File('${dir.path}/vault'));
      await store.initialize();
      await store.create('a sufficiently strong temporary master password');
      await store.put(VaultItem(
        id: 'mobile-account',
        kind: ItemKind.password,
        title: 'Mobile Account',
        secret: 'temporary-private-string',
        updatedAt: DateTime.utc(2026, 10, 29),
      ));
      return (dir: dir, store: store);
    });
    if (fixture == null) throw StateError('Test trezor nije pripremljen.');
    addTearDown(() async {
      if (await fixture.dir.exists()) {
        await fixture.dir.delete(recursive: true);
      }
    });
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: VaultShell(store: fixture.store),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mobile Account').first);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Detalji lozinke'), findsOneWidget);
    expect(find.byTooltip('Natrag'), findsOneWidget);
    expect(find.text('temporary-private-string'), findsNothing);

    await tester.runAsync(() async {
      await fixture.store.remove('mobile-account');
      await fixture.store.permanentlyRemove('mobile-account');
    });
    await tester.pumpAndSettle();
    expect(find.text('Zapis više nije dostupan.'), findsOneWidget);
    expect(find.text('temporary-private-string'), findsNothing);
    fixture.store.lock();
  }, timeout: const Timeout(Duration(minutes: 3)));
}
