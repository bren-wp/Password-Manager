import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/sensitive_clipboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String? clipboard;
  late Future<void>? Function(String) beforeWrite;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    clipboard = null;
    beforeWrite = (_) => null;
    messenger.setMockMethodCallHandler(SystemChannels.platform,
        (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          final text = (call.arguments as Map)['text'] as String;
          final block = beforeWrite(text);
          if (block != null) await block;
          clipboard = text;
          return null;
        case 'Clipboard.getData':
          return <String, dynamic>{'text': clipboard};
      }
      return null;
    });
  });

  tearDown(() async {
    await SensitiveClipboard.clear();
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('locking revokes the last copied password', () async {
    await SensitiveClipboard.copy('sensitive-test-password');
    expect(clipboard, 'sensitive-test-password');
    await SensitiveClipboard.clear();
    expect(clipboard, '');
  });

  test('locking does not erase unrelated clipboard content', () async {
    await SensitiveClipboard.copy('sensitive-test-password');
    await Clipboard.setData(const ClipboardData(text: 'user clipboard text'));
    await SensitiveClipboard.clear();
    expect(clipboard, 'user clipboard text');
  });

  test('locking invalidates a platform copy still in flight', () async {
    final gate = Completer<void>();
    beforeWrite = (value) =>
        value == 'delayed-secret' ? gate.future : null;
    final copying = SensitiveClipboard.copy('delayed-secret');
    // Give the platform mock time to enter its pending write.
    await Future<void>.delayed(Duration.zero);
    await SensitiveClipboard.clear();
    gate.complete();
    await copying;
    expect(clipboard, '',
        reason: 'An old copy must not reappear after the vault locked.');
  });

  test('a second copied secret supersedes the first', () async {
    await SensitiveClipboard.copy('first-secret');
    await SensitiveClipboard.copy('second-secret');
    expect(clipboard, 'second-secret');
    await SensitiveClipboard.clear();
    expect(clipboard, '');
  });
}
