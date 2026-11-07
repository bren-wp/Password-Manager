import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_store.dart';
import 'package:veldigo/ui/auth_screen.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/extra_pages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Windows unlock and setup retain desktop panel at 820px',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    final store = VaultStore(vaultFileOverride:
        File('${Directory.systemTemp.path}/veldigo-windows-auth-parity-unused'));
    addTearDown(store.dispose);

    for (final size in <Size>[
      const Size(820, 560),
      const Size(1200, 800),
      const Size(1586, 992),
    ]) {
      for (final create in <bool>[false, true]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(MaterialApp(
          theme: veldigoTheme().copyWith(platform: TargetPlatform.windows),
          home: AuthScreen(
            key: ValueKey('windows-auth-$size-$create'),
            store: store,
            create: create,
          ),
        ));
        await tester.pumpAndSettle();

        // Both halves of the reference-style Windows authentication panel
        // must be present; the Android-only logo appears in mobile mode.
        expect(find.text('Sigurno spremanje'), findsOneWidget,
            reason: 'Desktop layout must survive at $size.');
        expect(find.text('Potpuna privatnost'), findsOneWidget);

        final action = find.text(
            create ? 'Stvori sigurni trezor' : 'Otključaj trezor');
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        final rect = tester.getRect(action);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        expect(tester.takeException(), isNull,
            reason: 'Windows auth overflow at $size.');
      }
    }
  });

  testWidgets('Android create-vault keyboard proceeds to confirmation',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);

    final store = VaultStore(vaultFileOverride:
        File('${Directory.systemTemp.path}/veldigo-mobile-focus-parity-unused'));
    addTearDown(store.dispose);

    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: AuthScreen(store: store, create: true),
    ));
    await tester.pumpAndSettle();

    final fields = tester.widgetList<TextFormField>(
        find.byType(TextFormField)).toList();
    expect(fields, hasLength(2));
    expect(fields.first.textInputAction, TextInputAction.next);
    expect(fields.last.textInputAction, TextInputAction.done);
    await tester.enterText(find.byType(TextFormField).first,
        'Demo-only-Master-Password-2026!');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(find.text('Lozinke se ne podudaraju.'), findsNothing,
        reason: 'Next must not submit an unfinished create-vault form.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Windows generator slider produces one history entry per drag',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: const Scaffold(body: GeneratorPage()),
    ));
    await tester.pumpAndSettle();

    const lengthKey = ValueKey('veldigo-generator-length');
    const passwordKey = ValueKey('veldigo-generated-password');
    final slider = find.byKey(lengthKey);
    final original = tester.widget<SelectableText>(
        find.byKey(passwordKey)).data!;
    expect(original.length, 20);

    // Multiple intermediate pointer moves previously generated up to
    // five secret history entries during a single mouse drag.
    await tester.timedDrag(slider, const Offset(170, 0),
        const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    final current = tester.widget<SelectableText>(
        find.byKey(passwordKey)).data!;
    final selectedLength = tester.widget<Slider>(slider).value.toInt();
    expect(current.length, selectedLength);
    expect(current, isNot(original));
    expect(find.byTooltip('Kopiraj lozinku iz povijesti'), findsOneWidget);
    expect(find.text(original), findsNothing,
        reason: 'History never renders the previous secret in plaintext.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android 128-character preview remains on a single line',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: const Scaffold(body: GeneratorPage()),
    ));
    await tester.pumpAndSettle();

    const lengthKey = ValueKey('veldigo-generator-length');
    const passwordKey = ValueKey('veldigo-generated-password');
    final slider = find.byKey(lengthKey);
    await tester.ensureVisible(slider);
    await tester.timedDrag(slider, const Offset(300, 0),
        const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    final value = tester.widget<Slider>(slider).value.toInt();
    final password = tester.widget<SelectableText>(
        find.byKey(passwordKey));
    expect(value, greaterThan(20));
    expect(password.data!.length, value);
    expect(password.maxLines, 1,
        reason: 'Long secrets must scroll horizontally, not resize the card.');
    expect(tester.takeException(), isNull);
  });
}
