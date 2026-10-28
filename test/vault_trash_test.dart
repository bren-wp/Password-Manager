import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';

void main() {
  test('trash preserves credentials across relaunch until explicitly erased',
      () async {
    final temp = await Directory.systemTemp.createTemp('veldigo-trash-');
    try {
      final vaultPath = File('${temp.path}/vault');
      final vault = VaultStore(vaultFileOverride: vaultPath);
      await vault.initialize();
      await vault.create('a long local vault password');
      await vault.put(VaultItem(
        id: 'account-one', kind: ItemKind.password,
        title: 'Important account', secret: 'never lose this value',
        updatedAt: DateTime.utc(2026, 10, 28),
      ));
      await vault.remove('account-one');
      expect(vault.items.single.trashed, isTrue);
      expect(vault.items.single.secret, 'never lose this value');
      vault.lock();

      final reopened = VaultStore(vaultFileOverride: vaultPath);
      await reopened.initialize();
      await reopened.unlock('a long local vault password');
      expect(reopened.items.single.trashed, isTrue);
      await reopened.restoreTrashed('account-one');
      expect(reopened.items.single.trashed, isFalse);
      await reopened.remove('account-one');
      await reopened.permanentlyRemove('account-one');
      expect(reopened.items, isEmpty);
      reopened.lock();
      await reopened.unlock('a long local vault password');
      expect(reopened.items, isEmpty);
    } finally {
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
