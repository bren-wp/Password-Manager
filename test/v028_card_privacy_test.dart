import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/vault_shell.dart';

void main() {
  testWidgets('card gallery masks the full PAN and offers live detail actions',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;

    final demo = await tester.runAsync(() async {
      final directory = await Directory.systemTemp
          .createTemp('veldigo-cards-privacy-');
      final store = VaultStore(
        vaultFileOverride: File('${directory.path}/vault.veldigo'),
      );
      await store.initialize();
      await store.create('a very long disposable demo master password');
      await store.put(VaultItem(
        id: 'card-demo',
        kind: ItemKind.card,
        title: 'Demo kartica',
        username: 'DEMO USER',
        secret: '4111 1111 1111 4242',
        expiry: '12/28',
        cvv: '123',
        updatedAt: DateTime.utc(2026, 10, 29),
      ));
      return (directory: directory, store: store);
    });
    if (demo == null) throw StateError('Could not prepare demo vault');
    addTearDown(() async {
      demo.store.lock();
      demo.store.dispose();
      if (await demo.directory.exists()) {
        await demo.directory.delete(recursive: true);
      }
    });
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: VaultShell(store: demo.store, initialPage: 'Kartice'),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('4242'), findsWidgets);
    expect(find.textContaining('4111 1111 1111 4242'), findsNothing);
    expect(find.text('123'), findsNothing);
    expect(find.byTooltip('Zaključaj trezor'), findsOneWidget);

    await tester.tap(find.text('Demo kartica').first);
    await tester.pumpAndSettle();
    expect(find.text('Detalji kartice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
