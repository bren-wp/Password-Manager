import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_store.dart';

void main() {
  test('native file picker grace is scoped, bounded and revoked after use',
      () async {
    final temp = await Directory.systemTemp.createTemp('veldigo-picker-');
    try {
      final store = VaultStore(vaultFileOverride:
          File('${temp.path}/test-vault'));
      await store.initialize();
      await store.create('a very long and unique master passphrase');
      expect(store.externalPickerGraceActive, isFalse);

      final picker = Completer<String?>();
      final underway = store.withExternalFilePicker(() => picker.future);
      expect(store.externalPickerGraceActive, isTrue);
      picker.complete('backup.veldigo');
      expect(await underway, 'backup.veldigo');
      expect(store.externalPickerGraceActive, isFalse);

      final second = Completer<void>();
      final pending = store.withExternalFilePicker(() => second.future);
      expect(store.externalPickerGraceActive, isTrue);
      store.lock();
      expect(store.externalPickerGraceActive, isFalse);
      second.complete();
      await pending;
      await expectLater(
        store.withExternalFilePicker(() async => 'blocked'),
        throwsA(isA<StateError>()));
    } finally {
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
