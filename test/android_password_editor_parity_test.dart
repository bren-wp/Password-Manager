import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/entry_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openEditor(WidgetTester tester,
      {Future<void> Function(VaultItem)? onPersist}) async {
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: Scaffold(body: Builder(builder: (context) => Center(
        child: FilledButton(
          onPressed: () => showDialog<VaultItem>(
            context: context,
            barrierDismissible: false,
            builder: (_) => EntryEditor(
              kind: ItemKind.password, onPersist: onPersist),
          ),
          child: const Text('Open editor'),
        ),
      ))),
    ));
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
  }

  testWidgets('Android password editor preserves mobile reference structure',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final written = <VaultItem>[];
    await openEditor(tester,
      onPersist: (item) async { written.add(item); });
    expect(find.text('Nova lozinka'), findsOneWidget);
    expect(find.text('Odaberite ikonu'), findsOneWidget);
    expect(find.byKey(const ValueKey('service-github')), findsOneWidget);
    expect(find.byKey(const ValueKey('editor-mobile-scroll')), findsOneWidget);
    expect(find.text('Spremi lozinku'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('service-github')));
    await tester.pumpAndSettle();
    final title = tester.widget<TextFormField>(
      find.byKey(const ValueKey('editor-title')));
    final website = tester.widget<TextFormField>(
      find.byKey(const ValueKey('editor-website')));
    expect(title.controller!.text, 'GitHub');
    expect(website.controller!.text, 'https://github.com');

    // Presets never supply credentials automatically.
    final password = tester.widget<TextFormField>(
      find.byKey(const ValueKey('editor-secret')));
    expect(password.controller!.text, isEmpty);
    final nativePasswordField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('editor-secret')),
        matching: find.byType(TextField),
      ),
    );
    expect(nativePasswordField.autocorrect, isFalse);
    expect(nativePasswordField.enableSuggestions, isFalse);
    expect(nativePasswordField.enableIMEPersonalizedLearning, isFalse);

    await tester.ensureVisible(find.byKey(const ValueKey('editor-secret')));
    await tester.enterText(find.byKey(const ValueKey('editor-secret')),
      'strong-secret-generated-in-a-test-12!');
    await tester.pump();
    // Finder text matches EditableText internals even when masked; verify
    // the actual rendered input privacy contract instead.
    expect(tester.widget<TextField>(find.descendant(
      of: find.byKey(const ValueKey('editor-secret')),
      matching: find.byType(TextField),
    )).obscureText, isTrue,
      reason: 'The password input must mask characters by default.');

    await tester.ensureVisible(find.byKey(const ValueKey('editor-username')));
    await tester.enterText(find.byKey(const ValueKey('editor-username')),
      'developer@example.test');
    await tester.pump();

    await tester.ensureVisible(find.byKey(const ValueKey('editor-notes')));
    await tester.enterText(find.byKey(const ValueKey('editor-notes')),
      'Local-only sample note');
    final notes = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('editor-notes')),
        matching: find.byType(TextField),
      ),
    );
    expect(notes.maxLength, 500);

    await tester.ensureVisible(find.byKey(const ValueKey('editor-favorite')));
    await tester.tap(find.byKey(const ValueKey('editor-favorite')));
    await tester.pump();
    expect(tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('editor-favorite'))).value, isTrue);

    await tester.tap(find.text('Spremi lozinku'));
    await tester.pumpAndSettle();
    expect(written, hasLength(1));
    expect(written.single.title, 'GitHub');
    expect(written.single.website, 'https://github.com');
    expect(written.single.username, 'developer@example.test');
    expect(written.single.secret, 'strong-secret-generated-in-a-test-12!');
    expect(written.single.notes, 'Local-only sample note');
    expect(written.single.favorite, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile save failure does not discard typed credentials',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pending = Completer<void>();
    await openEditor(tester, onPersist: (_) => pending.future);
    await tester.tap(find.byKey(const ValueKey('service-google')));
    await tester.ensureVisible(find.byKey(const ValueKey('editor-secret')));
    await tester.enterText(find.byKey(const ValueKey('editor-secret')),
      'private-password-must-survive-save-failure');
    await tester.tap(find.text('Spremi lozinku'));
    await tester.pump();
    expect(find.text('Spremanje…'), findsOneWidget);
    pending.completeError(const FileSystemException('write failure'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Spremanje nije uspjelo'), findsOneWidget);
    final field = tester.widget<TextFormField>(
      find.byKey(const ValueKey('editor-secret')));
    expect(field.controller!.text, 'private-password-must-survive-save-failure');
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile password editor scrolls safely on compact phones',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in <Size>[
      const Size(320, 640),
      const Size(393, 852),
      const Size(480, 900),
    ]) {
      tester.view.physicalSize = size;
      await openEditor(tester);
      expect(find.text('Spremi lozinku'), findsOneWidget);
      final bottom = tester.getRect(find.text('Spremi lozinku')).bottom;
      expect(bottom, lessThanOrEqualTo(size.height));
      await tester.ensureVisible(find.byKey(const ValueKey('editor-notes')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      // Close the dialog rather than carrying the current editor into the
      // next test viewport.
      await tester.tap(find.byTooltip('Natrag'));
      await tester.pumpAndSettle();
    }
  });
}
