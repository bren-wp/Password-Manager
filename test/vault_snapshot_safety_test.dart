import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';

void main() {
  test('import preserves verified encrypted pre-import copy of newer records',
      () async {
    final dir = await Directory.systemTemp.createTemp('veldigo-import-snapshot-');
    try {
      final source = File('${dir.path}/active.vault');
      final vault = VaultStore(vaultFileOverride: source);
      await vault.initialize();
      await vault.create('long and unique test master password');
      await vault.put(VaultItem(id: 'before', kind: ItemKind.password,
        title: 'First account', secret: 'secret-before-import',
        updatedAt: DateTime.utc(2026, 10, 28)));
      final oldBackup = await vault.encryptedBackup();
      await vault.put(VaultItem(id: 'after', kind: ItemKind.password,
        title: 'Recent account', secret: 'secret-not-in-old-backup',
        updatedAt: DateTime.utc(2026, 10, 28)));
      await vault.restore(oldBackup, 'long and unique test master password');
      expect(vault.items.length, 1);
      final snapshots = dir.listSync().where((entry) =>
        entry.path.contains('.before-import-')).toList();
      expect(snapshots, hasLength(1));

      final recovered = VaultStore(
        vaultFileOverride: File(snapshots.single.path));
      await recovered.initialize();
      await recovered.unlock('long and unique test master password');
      expect(recovered.items.map((entry) => entry.id).toSet(),
        {'before', 'after'});
    } finally {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('master key change preserves verified old-key encrypted snapshot',
      () async {
    final dir = await Directory.systemTemp.createTemp('veldigo-key-snapshot-');
    try {
      final path = File('${dir.path}/active.vault');
      final vault = VaultStore(vaultFileOverride: path);
      await vault.initialize();
      await vault.create('previous very strong master phrase');
      await vault.put(VaultItem(id: 'credential', kind: ItemKind.password,
        title: 'Example', secret: 'important-example-secret',
        updatedAt: DateTime.utc(2026, 10, 28)));
      await vault.changeMasterPassword(
        'previous very strong master phrase', 'new very strong master phrase');
      vault.lock();
      await vault.unlock('new very strong master phrase');
      expect(vault.items.single.id, 'credential');
      final snapshots = dir.listSync().where((entry) =>
        entry.path.contains('.before-password-change-')).toList();
      expect(snapshots, hasLength(1));
      final restored = VaultStore(vaultFileOverride: File(snapshots.single.path));
      await restored.initialize();
      await restored.unlock('previous very strong master phrase');
      expect(restored.items.single.secret, 'important-example-secret');
    } finally {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
