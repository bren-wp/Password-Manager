import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/entry_editor.dart';

void main() {
  testWidgets('failed encrypted save keeps password editor and typed secrets',
      (tester) async {
    final result = Completer<void>();
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: Scaffold(body: Builder(builder: (context) => Center(
        child: FilledButton(
          onPressed: () => showDialog<VaultItem>(
            barrierDismissible: false,
            context: context,
            builder: (_) => EntryEditor(
              kind: ItemKind.password,
              onPersist: (item) => result.future,
            ),
          ),
          child: const Text('Open editor'),
        ),
      ))),
    ));
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Important account');
    await tester.enterText(fields.at(2), 'a valuable test-only password');
    await tester.tap(find.text('Spremi'));
    await tester.pump();
    expect(find.text('Spremanje…'), findsOneWidget);
    // The asynchronous save is still underway. The dialog stays open.
    expect(find.text('Important account'), findsOneWidget);
    result.completeError(const FileSystemException('Test write failure'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Spremanje nije uspjelo'), findsOneWidget);
    final secretField = tester.widget<TextFormField>(fields.at(2));
    expect(secretField.controller!.text, 'a valuable test-only password');
    expect(find.text('Spremi'), findsOneWidget);
  });

  testWidgets('successful encrypted persistence completes before editor closes',
      (tester) async {
    final writes = <VaultItem>[];
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: Scaffold(body: Builder(builder: (context) => Center(
        child: FilledButton(
          onPressed: () => showDialog<VaultItem>(
            barrierDismissible: false,
            context: context,
            builder: (_) => EntryEditor(
              kind: ItemKind.password,
              onPersist: (item) async { writes.add(item); },
            ),
          ),
          child: const Text('Open editor'),
        ),
      ))),
    ));
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'GitHub demo');
    await tester.enterText(fields.at(2), 'demo only example password');
    await tester.tap(find.text('Spremi'));
    await tester.pumpAndSettle();
    expect(writes, hasLength(1));
    expect(writes.single.secret, 'demo only example password');
    expect(find.text('Dodaj novu lozinku'), findsNothing);
  });
}
