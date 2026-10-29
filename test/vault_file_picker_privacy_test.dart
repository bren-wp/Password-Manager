import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_store.dart';

void main() {
  const password = 'a very long and unique master passphrase';

  test('native file picker grace is scoped, bounded and revoked after use',
      () async {
    final temp = await Directory.systemTemp.createTemp('veldigo-picker-');
    final store = VaultStore(vaultFileOverride:
        File('${temp.path}/test-vault'));
    try {
      await store.initialize();
      await store.create(password);
      expect(store.externalPickerGraceActive, isFalse);

      final picker = Completer<String?>();
      final underway = store.withExternalFilePicker(() => picker.future);
      expect(store.externalPickerGraceActive, isTrue);
      picker.complete('backup.veldigo');
      expect(await underway, 'backup.veldigo');
      expect(store.externalPickerGraceActive, isFalse);

      final second = Completer<void>();
      final pending = store.withExternalFilePicker(() => second.future);
      final cancelled = expectLater(
          pending, throwsA(isA<VaultSessionCancelledException>()));
      expect(store.externalPickerGraceActive, isTrue);
      store.lock();
      expect(store.externalPickerGraceActive, isFalse);
      second.complete();
      await cancelled;
      await expectLater(
        store.withExternalFilePicker(() async => 'blocked'),
        throwsA(isA<StateError>()));
    } finally {
      store.dispose();
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('stale picker completion cannot revive or cancel a new session grace',
      () async {
    final temp = await Directory.systemTemp.createTemp('veldigo-picker-race-');
    final store = VaultStore(vaultFileOverride:
        File('${temp.path}/test-vault'));
    try {
      await store.initialize();
      await store.create(password);
      final stalePicker = Completer<String?>();
      final staleOperation =
          store.withExternalFilePicker(() => stalePicker.future);
      final cancelled = expectLater(staleOperation,
          throwsA(isA<VaultSessionCancelledException>()));
      expect(store.externalPickerGraceActive, isTrue);

      store.lock();
      await store.unlock(password);
      expect(store.externalPickerGraceActive, isFalse,
          reason: 'A locked session must not preserve picker grace.');

      final freshPicker = Completer<String?>();
      final freshOperation =
          store.withExternalFilePicker(() => freshPicker.future);
      expect(store.externalPickerGraceActive, isTrue);
      stalePicker.complete('stale.veldigo');
      await cancelled;
      expect(store.externalPickerGraceActive, isTrue,
          reason: 'A stale picker must not cancel a new picker timeout.');

      freshPicker.complete('fresh.veldigo');
      expect(await freshOperation, 'fresh.veldigo');
      expect(store.externalPickerGraceActive, isFalse);
    } finally {
      store.dispose();
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('multiple pickers in one session keep grace until the last closes',
      () async {
    final temp = await Directory.systemTemp.createTemp('veldigo-picker-nested-');
    final store = VaultStore(vaultFileOverride:
        File('${temp.path}/test-vault'));
    try {
      await store.initialize();
      await store.create(password);
      final first = Completer<void>();
      final second = Completer<void>();
      final firstOperation = store.withExternalFilePicker(() => first.future);
      final secondOperation = store.withExternalFilePicker(() => second.future);
      expect(store.externalPickerGraceActive, isTrue);

      first.complete();
      await firstOperation;
      expect(store.externalPickerGraceActive, isTrue);
      second.complete();
      await secondOperation;
      expect(store.externalPickerGraceActive, isFalse);
    } finally {
      store.dispose();
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
