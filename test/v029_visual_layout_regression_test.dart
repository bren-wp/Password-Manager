import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/entry_editor.dart';
import 'package:veldigo/ui/welcome_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first-run actions remain visible on compact and full phones',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in <Size>[
      const Size(320, 640),
      const Size(360, 740),
      const Size(393, 852),
      const Size(416, 928),
    ]) {
      tester.view.physicalSize = size;
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        theme: veldigoTheme(),
        home: WelcomeScreen(onStart: () => tapped = true),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: 'welcome overflow at $size');
      final start = find.text('Započni');
      final import = find.text('Već imate trezor? Uvezite kopiju');
      expect(start, findsOneWidget);
      expect(import, findsOneWidget);
      final startRect = tester.getRect(start);
      final importRect = tester.getRect(import);
      expect(startRect.top, greaterThanOrEqualTo(0));
      expect(importRect.bottom, lessThanOrEqualTo(size.height),
          reason: 'the backup entry point must not require scrolling');
      await tester.tap(start);
      expect(tapped, isTrue);
    }
  });

  testWidgets('editor actions fit 320dp width without RenderFlex overflow',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: Builder(builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showDialog<VaultItem>(
            context: context,
            builder: (_) => const EntryEditor(kind: ItemKind.password)),
          child: const Text('Otvori urednik'),
        ),
      )),
    ));
    await tester.tap(find.text('Otvori urednik'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Nova lozinka'), findsOneWidget);
    expect(find.text('Odustani'), findsOneWidget);
    expect(find.text('Spremi'), findsOneWidget);
    final saveRect = tester.getRect(find.text('Spremi'));
    expect(saveRect.right, lessThanOrEqualTo(320));
    expect(saveRect.bottom, lessThanOrEqualTo(640));
    await tester.tap(find.text('Odustani'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared styling remains consistent in Android and Windows',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: Builder(builder: (context) {
        final theme = Theme.of(context);
        expect(theme.scaffoldBackgroundColor, VColors.background);
        expect(theme.textTheme.headlineMedium?.fontSize, 24);
        expect(theme.textTheme.titleLarge?.fontSize, 19);
        expect(theme.appBarTheme.toolbarHeight, 56);
        expect(
          theme.outlinedButtonTheme.style?.textStyle
              ?.resolve(<WidgetState>{})?.fontFamily,
          'Roboto',
          reason: 'Secondary button labels must not render in Ahem.');
        return const Scaffold(
          body: VPanel(child: VSectionHeader(
            title: 'Pristupni podaci',
            subtitle: 'Zaštićeni lokalnim šifriranjem.',
            trailing: Icon(Icons.lock_outline),
          )),
        );
      }),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('Pristupni podaci'), findsOneWidget);
  });
}
