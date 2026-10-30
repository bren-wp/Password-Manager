import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/mobile_password_details.dart';
import 'package:veldigo/ui/vault_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({Directory dir, VaultStore store})> fixture() async {
    final dir = await Directory.systemTemp
        .createTemp('veldigo-android-details-');
    final store = VaultStore(
      vaultFileOverride: File('${dir.path}/vault'));
    await store.initialize();
    await store.create('strong-test-only-master-password-details-2026');
    await store.put(VaultItem(
      id: 'github-test',
      kind: ItemKind.password,
      title: 'GitHub',
      username: 'developer@example.test',
      website: 'https://github.com',
      notes: '2FA is enabled locally.',
      secret: 'private-password-not-for-logs',
      category: 'Posao',
      updatedAt: DateTime.utc(2026, 10, 24, 12),
    ));
    return (dir: dir, store: store);
  }

  testWidgets('Android 05 shows separate panels and masks saved password',
      (tester) async {
    final testVault = await tester.runAsync(fixture);
    if (testVault == null) throw StateError('Fixture could not be created');
    addTearDown(() async {
      testVault.store.lock();
      testVault.store.dispose();
      if (await testVault.dir.exists()) {
        await testVault.dir.delete(recursive: true);
      }
    });
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: VaultShell(store: testVault.store),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GitHub').first);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(MobilePasswordDetails), findsOneWidget);
    expect(find.text('Detalji lozinke'), findsOneWidget);
    expect(find.text('Korisničko ime'), findsOneWidget);
    expect(find.text('Lozinka'), findsOneWidget);
    expect(find.text('Web-adresa'), findsOneWidget);
    expect(find.descendant(
      of: find.byType(MobilePasswordDetails),
      matching: find.text('Bilješke'),
    ), findsOneWidget,
      reason: 'Only the detail card label is counted, not the dashboard stat.');
    expect(find.text('Zadnja izmjena'), findsOneWidget);
    expect(find.text('Kopiraj lozinku'), findsOneWidget);
    expect(find.text('developer@example.test'), findsOneWidget);
    expect(find.text('private-password-not-for-logs'), findsNothing);
    expect(tester.widget<Text>(
      find.byKey(const ValueKey('mobile-detail-password'))).data,
      '••••••••••');

    await tester.tap(find.byTooltip('Prikaži'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(
      find.byKey(const ValueKey('mobile-detail-password'))).data,
      'private-password-not-for-logs');
    await tester.tap(find.byTooltip('Sakrij'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(
      find.byKey(const ValueKey('mobile-detail-password'))).data,
      '••••••••••');

    // Sharing must not silently exfiltrate credentials to a third party.
    final share = find.text('Podijeli');
    await tester.scrollUntilVisible(share, 170,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('mobile-password-details')),
        matching: find.byType(Scrollable),
      ));
    final button = tester.widget<InkWell>(find.ancestor(
      of: share, matching: find.byType(InkWell)).first);
    expect(button.onTap, isNull,
      reason: 'Unsupported secret sharing must be clearly disabled.');
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('Android 05 remains usable at narrow and tall phone widths',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in <Size>[
      const Size(320, 640),
      const Size(393, 852),
      const Size(431, 912),
    ]) {
      tester.view.physicalSize = size;
      final item = VaultItem(
        id: 'test-item', kind: ItemKind.password,
        title: 'Example account',
        username: 'sample@example.test',
        secret: 'secret-without-any-logging',
        website: 'https://example.test',
        updatedAt: DateTime.utc(2026, 10, 24),
      );
      await tester.pumpWidget(MaterialApp(
        theme: veldigoTheme(),
        home: Scaffold(body: MobilePasswordDetails(
          key: ValueKey('mobile-details-$size'),
          item: item,
          onCopy: (s) async {},
          onEdit: () {},
          onRemove: () {},
          onRestore: () {},
          onErase: () {},
        )),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Detalji lozinke'), findsOneWidget);
      expect(tester.takeException(), isNull,
        reason: 'Password details should not overflow at $size');
      final delete = find.text('Obriši');
      await tester.scrollUntilVisible(delete, 170,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('mobile-password-details')),
          matching: find.byType(Scrollable),
        ));
      await tester.pumpAndSettle();
      final rect = tester.getRect(delete);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(size.width));
      expect(rect.bottom, lessThanOrEqualTo(size.height));
      expect(tester.takeException(), isNull);
    }
  });
}
