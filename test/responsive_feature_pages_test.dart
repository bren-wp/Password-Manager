import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/vault_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('all vault sections render on minimum mobile and desktop sizes',
      (tester) async {
    final prepared = await tester.runAsync(() async {
      final directory = await Directory.systemTemp
          .createTemp('veldigo-all-pages-responsive-');
      final store = VaultStore(
          vaultFileOverride: File('${directory.path}/vault.veldigo'));
      await store.initialize();
      await store.create('a private demo-only master password');
      await store.put(VaultItem(
        id: 'demo-password',
        kind: ItemKind.password,
        title: 'Example account',
        username: 'demo@example.test',
        secret: 'test-only-secret-2026!',
        category: 'Osobno',
        updatedAt: DateTime.utc(2026, 10, 29),
      ));
      await store.put(VaultItem(
        id: 'demo-note',
        kind: ItemKind.note,
        title: 'Example note',
        notes: 'A placeholder without personal information.',
        category: 'Posao',
        updatedAt: DateTime.utc(2026, 10, 29),
      ));
      return (directory: directory, store: store);
    });
    if (prepared == null) {
      throw StateError('Could not prepare a demonstration vault');
    }
    final store = prepared.store;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(() async {
      store.lock();
      store.dispose();
      if (await prepared.directory.exists()) {
        await prepared.directory.delete(recursive: true);
      }
    });
    tester.view.devicePixelRatio = 1;

    const sections = <String>[
      'Trezor',
      'Sve lozinke',
      'Favoriti',
      'Kategorije',
      'Sigurne bilješke',
      'Kartice',
      'Autentifikator',
      'Generator',
      'Sigurnost',
      'Sigurnosna kopija',
      'Koš',
      'Postavke',
    ];
    const viewports = <Size>[
      Size(320, 640),
      Size(360, 740),
      Size(393, 852),
      Size(820, 560),
      Size(1200, 800),
      Size(1600, 900),
    ];

    for (final size in viewports) {
      tester.view.physicalSize = size;
      for (final section in sections) {
        await tester.pumpWidget(MaterialApp(
          theme: veldigoTheme(),
          home: VaultShell(
            key: ValueKey('${size.width}-${size.height}-$section'),
            store: store,
            initialPage: section,
          ),
        ));
        await tester.pump();
        final failure = tester.takeException();
        expect(failure, isNull,
            reason: 'Overflow or build failure in $section at '
                '${size.width}x${size.height}');
        expect(find.byType(VaultShell), findsOneWidget);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 5)));
}
