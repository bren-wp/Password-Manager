import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_files.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';

void main() {
  test('authenticated quarantined vault remains recoverable if primary lost',
      () async {
    final dir = await Directory.systemTemp.createTemp('veldigo-quarantine-');
    try {
      final file = File('${dir.path}/vault.veldigo');
      const password = 'quarantine recovery master password test';
      final writer = VaultStore(vaultFileOverride: file);
      await writer.initialize();
      await writer.create(password);
      await writer.put(VaultItem(
        id: 'protected-account',
        kind: ItemKind.password,
        title: 'Important account',
        secret: 'must-not-be-lost',
        updatedAt: DateTime.utc(2026, 10, 29),
      ));
      final saved = await writer.encryptedBackup();
      writer.lock();

      final copies = VaultFiles(file, verify: (bytes) async => bytes.isNotEmpty);
      await copies.quarantine.writeAsBytes(saved, flush: true);
      for (final candidate in [
        file, copies.previous, copies.older, copies.swap, copies.pending,
        copies.previousRetired, copies.olderRetired, copies.recoveryStage,
      ]) {
        if (await candidate.exists()) await candidate.delete();
      }

      final reopened = VaultStore(vaultFileOverride: file);
      await reopened.initialize();
      await reopened.unlock(password);
      expect(reopened.items.single.id, 'protected-account');
      expect(reopened.items.single.secret, 'must-not-be-lost');
      expect(await file.readAsBytes(), saved);
    } finally {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('invalid quarantined bytes never create a replacement vault', () async {
    final dir = await Directory.systemTemp.createTemp('veldigo-quarantine-');
    try {
      final file = File('${dir.path}/vault.veldigo');
      await File('${file.path}.corrupt')
          .writeAsString('not authenticated', flush: true);
      final store = VaultStore(vaultFileOverride: file);
      await store.initialize();
      expect(store.hasVault, isTrue);
      await expectLater(store.unlock('a long incorrect master password'),
          throwsA(isA<VaultAuthenticationException>()));
      expect(store.isUnlocked, isFalse);
      expect(await file.exists(), isFalse);
    } finally {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
