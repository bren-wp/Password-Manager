import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';

void main() {
  test('writes remain possible after rotation with existing retired backups',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('veldigo-key-rotation-');
    final file = File('${directory.path}/vault.veldigo');
    final vault = VaultStore(vaultFileOverride: file);
    const oldPassword = 'a long original master password for this test';
    const newPassword = 'a different long master password for this test';
    try {
      await vault.initialize();
      await vault.create(oldPassword);
      for (var i = 0; i < 6; i++) {
        await vault.put(VaultItem(
          id: 'before-$i',
          kind: ItemKind.password,
          title: 'Existing account $i',
          secret: 'demo secret $i',
          updatedAt: DateTime.utc(2026, 10, 29),
        ));
      }
      // Multiple saves produce both .bak and .bak.retired generations.
      expect(await File('${file.path}.bak.retired').exists(), isTrue);

      await vault.changeMasterPassword(oldPassword, newPassword);
      for (var i = 0; i < 3; i++) {
        await vault.put(VaultItem(
          id: 'after-$i',
          kind: ItemKind.password,
          title: 'New account $i',
          secret: 'new demo secret $i',
          updatedAt: DateTime.utc(2026, 10, 29),
        ));
      }

      final legacy = directory
          .listSync()
          .whereType<File>()
          .where((item) => item.path.contains('.retired-legacy-'))
          .toList();
      expect(legacy, isNotEmpty,
          reason: 'Older encrypted generations must not be deleted');
      vault.lock();
      final reopened = VaultStore(vaultFileOverride: file);
      await reopened.initialize();
      await reopened.unlock(newPassword);
      expect(reopened.items.length, 9);
      expect(reopened.items.map((item) => item.id).toSet().length, 9);
      reopened.lock();
      reopened.dispose();
    } finally {
      vault.lock();
      vault.dispose();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
