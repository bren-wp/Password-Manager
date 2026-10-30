import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/vault_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android home keeps independent cards, safe search and sorting',
      (tester) async {
    final fixture = await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('veldigo-home-ui-');
      final store = VaultStore(vaultFileOverride: File('${dir.path}/vault'));
      await store.initialize();
      await store.create('unique test-only master passphrase for UI');
      await store.put(VaultItem(
        id: 'zeta',
        kind: ItemKind.password,
        title: 'Zeta Account',
        username: 'zeta@example.test',
        secret: 'a-very-private-zeta-secret',
        updatedAt: DateTime.utc(2026, 10, 28, 14),
      ));
      await store.put(VaultItem(
        id: 'alpha',
        kind: ItemKind.password,
        title: 'Alpha Account',
        username: 'alpha@example.test',
        secret: 'a-very-private-alpha-secret',
        updatedAt: DateTime.utc(2026, 10, 26, 12),
      ));
      return (dir: dir, store: store);
    });
    if (fixture == null) throw StateError('Test vault initialization failed.');
    addTearDown(() async {
      fixture.store.lock();
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

    expect(find.text('Moje lozinke'), findsOneWidget);
    expect(find.text('Zeta Account'), findsOneWidget);
    expect(find.text('Alpha Account'), findsOneWidget);
    expect(find.text('a-very-private-zeta-secret'), findsNothing);
    expect(find.text('a-very-private-alpha-secret'), findsNothing);
    expect(find.byKey(const ValueKey('veldigo-search-sort')), findsOneWidget);
    expect(find.byKey(const ValueKey('veldigo-list-sort')), findsOneWidget);

    // The reference has independent password tiles, not one enclosing panel.
    final alphaTile = find.ancestor(
      of: find.text('Alpha Account'), matching: find.byType(InkWell)).first;
    final zetaTile = find.ancestor(
      of: find.text('Zeta Account'), matching: find.byType(InkWell)).first;
    expect(tester.getRect(alphaTile).top,
        greaterThan(tester.getRect(zetaTile).top));

    await tester.tap(find.byKey(const ValueKey('veldigo-search-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Po nazivu').last);
    await tester.pumpAndSettle();
    expect(find.text('Po nazivu'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Alpha Account')).dy,
        lessThan(tester.getTopLeft(find.text('Zeta Account')).dy));

    await tester.enterText(find.byType(TextField).first, 'zeta');
    await tester.pumpAndSettle();
    expect(find.text('Zeta Account'), findsOneWidget);
    expect(find.text('Alpha Account'), findsNothing);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('Android vault home remains usable on compact phone',
      (tester) async {
    final fixture = await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('veldigo-home-compact-');
      final store = VaultStore(vaultFileOverride: File('${dir.path}/vault'));
      await store.initialize();
      await store.create('another sufficiently long test-only passphrase');
      await store.put(VaultItem(
        id: 'demo',
        kind: ItemKind.password,
        title: 'Google',
        secret: 'never-render-this-plaintext',
        updatedAt: DateTime.utc(2026, 10, 30),
      ));
      return (dir: dir, store: store);
    });
    if (fixture == null) throw StateError('Test vault initialization failed.');
    addTearDown(() async {
      fixture.store.lock();
      if (await fixture.dir.exists()) {
        await fixture.dir.delete(recursive: true);
      }
    });
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in <Size>[
      const Size(320, 640),
      const Size(393, 852),
      const Size(480, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(MaterialApp(
        key: ValueKey('vault-$size'),
        theme: veldigoTheme(),
        home: VaultShell(store: fixture.store),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('never-render-this-plaintext'), findsNothing);
      expect(find.byTooltip('Dodaj novu lozinku'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
