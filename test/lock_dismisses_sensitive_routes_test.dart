import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_store.dart';
import 'package:veldigo/main.dart';
import 'package:veldigo/ui/auth_screen.dart';
import 'package:veldigo/ui/entry_editor.dart';
import 'package:veldigo/ui/vault_shell.dart';

void main() {
  testWidgets('locking vault removes every sensitive editor route',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    final prepared = await tester.runAsync(() async {
      final temp = await Directory.systemTemp.createTemp('veldigo-lock-ui-');
      final store = VaultStore(
        vaultFileOverride: File('${temp.path}/vault.veldigo'),
      );
      await store.initialize();
      await store.create('very long demo-only master password');
      return (temp: temp, store: store);
    });
    if (prepared == null) {
      throw StateError('Test vault creation failed');
    }
    final store = prepared.store;
    addTearDown(() async {
      if (await prepared.temp.exists()) {
        await prepared.temp.delete(recursive: true);
      }
    });

    await tester.pumpWidget(VeldigoApp(storeOverride: store));
    await tester.pumpAndSettle();
    expect(find.byType(VaultShell), findsOneWidget);
    await tester.tap(find.byTooltip('Dodaj novu lozinku'));
    await tester.pumpAndSettle();
    expect(find.byType(EntryEditor), findsOneWidget);

    // The unlocked editor is above the home route. Locking must dismiss
    // it, not merely replace the obscured home with the unlock screen.
    store.lock();
    await tester.pumpAndSettle();
    expect(find.byType(EntryEditor), findsNothing);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 4)));
}
