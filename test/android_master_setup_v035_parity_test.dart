import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_store.dart';
import 'package:veldigo/ui/auth_screen.dart';
import 'package:veldigo/ui/brand.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android master setup follows reference form grouping without '
      'weakening vault security', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(443.5, 887);
    final store = VaultStore(vaultFileOverride:
        File('${Directory.systemTemp.path}/veldigo-setup-v035-test-unused'));
    addTearDown(store.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: AuthScreen(store: store, create: true, onBack: () {}),
    ));
    await tester.pumpAndSettle();

    const masterKey = ValueKey('veldigo-master-password-field');
    const confirmationKey = ValueKey('veldigo-confirm-password-field');
    expect(find.byKey(masterKey), findsOneWidget);
    expect(find.byKey(confirmationKey), findsOneWidget);
    expect(find.text('Najmanje 12 znakova'), findsOneWidget);
    expect(find.text('Najmanje 8 znakova'), findsNothing);
    expect(find.text('Zaštitite svoj trezor'), findsOneWidget);

    final primary = find.text('Stvori sigurni trezor');
    await tester.ensureVisible(primary);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_forward), findsWidgets);
    expect(find.byKey(const ValueKey('veldigo-setup-import')), findsOneWidget);
    final import = find.byKey(const ValueKey('veldigo-setup-import'));
    expect(tester.getRect(import).top,
        greaterThan(tester.getRect(primary).top));
    expect(tester.getRect(import).bottom,
        lessThanOrEqualTo(887));
    expect(tester.takeException(), isNull);
    expect(store.hasVault, isFalse);
    expect(store.isUnlocked, isFalse);
  });

  testWidgets('Android setup keeps the footer and actions scrollable at '
      'small widths with large text', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    final store = VaultStore(vaultFileOverride:
        File('${Directory.systemTemp.path}/veldigo-setup-small-v035-unused'));
    addTearDown(store.dispose);

    for (final size in <Size>[
      const Size(320, 640), const Size(393, 852),
      const Size(480, 900),
    ]) {
      for (final zoom in <double>[1, 1.5]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(MaterialApp(
          key: ValueKey('v035-$size-$zoom'),
          theme: veldigoTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(zoom)),
            child: child!,
          ),
          home: AuthScreen(
            key: ValueKey('setup-$size-$zoom'),
            store: store, create: true, onBack: () {},
          ),
        ));
        await tester.pumpAndSettle();
        final submit = find.text('Stvori sigurni trezor');
        final import = find.byKey(const ValueKey('veldigo-setup-import'));
        await tester.ensureVisible(import);
        await tester.pumpAndSettle();
        expect(tester.getRect(import).bottom, lessThanOrEqualTo(size.height));
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        expect(tester.getRect(submit).bottom, lessThanOrEqualTo(size.height));
        expect(tester.takeException(), isNull,
            reason: 'overflow at $size text-scale $zoom');
      }
    }
  });

  testWidgets('Windows setup retains its original import action and '
      'independent password controls', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    final store = VaultStore(vaultFileOverride:
        File('${Directory.systemTemp.path}/veldigo-setup-windows-v035-unused'));
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme().copyWith(platform: TargetPlatform.windows),
      home: AuthScreen(store: store, create: true),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Sigurno spremanje'), findsOneWidget);
    expect(find.text('Uvezi postojeću šifriranu kopiju'), findsOneWidget);
    expect(find.byKey(const ValueKey('veldigo-setup-import')), findsNothing);
    expect(find.text('Najmanje 12 znakova'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
