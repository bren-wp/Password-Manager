import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';

void main() {
  const master = 'a sufficiently long unique test master password';
  const replacement = 'a separate sufficiently long replacement password';

  VaultItem item(String id) => VaultItem(
        id: id,
        kind: ItemKind.password,
        title: 'Private example $id',
        secret: 'offline-test-only-$id',
        updatedAt: DateTime.utc(2026, 10, 30),
      );

  test('operations queued after unlock while still locked are denied',
      () async {
    final temp = await Directory.systemTemp.createTemp('veldigo-queue-lock-');
    final store = VaultStore(
        vaultFileOverride: File('${temp.path}/vault.veldigo'));
    try {
      await store.initialize();
      await store.create(master);
      await store.put(item('baseline'));
      final originalBackup = await store.encryptedBackup();

      // The unlock is ahead of each command in the asynchronous queue.
      // A stale UI command issued while LOCKED must never inherit that
      // future authenticated session, even if the command executes later.
      final operations = <(String, Future<void> Function())>[
        ('save', () => store.save()),
        ('put', () => store.put(item('unauthorized'))),
        ('remove', () => store.remove('baseline')),
        ('restoreTrashed', () => store.restoreTrashed('baseline')),
        ('permanentlyRemove', () => store.permanentlyRemove('baseline')),
        ('encryptedBackup', () async { await store.encryptedBackup(); }),
        ('changeMasterPassword', () =>
            store.changeMasterPassword(master, replacement)),
        ('restore', () => store.restore(originalBackup, master)),
      ];
      for (final (name, operation) in operations) {
        store.lock();
        final unlock = store.unlock(master);
        final denied = expectLater(operation(), throwsA(isA<StateError>()),
            reason: '$name requested while locked must fail closed');
        await unlock;
        await denied;
        expect(store.isUnlocked, isTrue);
        expect(store.items.map((record) => record.id), ['baseline']);
        expect(store.items.single.trashed, isFalse);
      }
      store.lock();
      await store.unlock(master);
      expect(store.items.map((record) => record.id), ['baseline']);
    } finally {
      store.dispose();
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('a pending write from an earlier session cannot run after relock',
      () async {
    final temp = await Directory.systemTemp.createTemp('veldigo-queue-epoch-');
    final store = VaultStore(
        vaultFileOverride: File('${temp.path}/vault.veldigo'));
    try {
      await store.initialize();
      await store.create(master);
      final pending = store.put(item('old-session'));
      final rejected = expectLater(pending,
          throwsA(isA<VaultSessionCancelledException>()));
      // The serialization queue yields even for a completed prior operation,
      // giving lock() a chance to invalidate the request before it starts.
      store.lock();
      final reopened = store.unlock(master);
      await rejected;
      await reopened;
      expect(store.items, isEmpty,
          reason: 'An old queued put must not touch the new session.');
      await store.put(item('fresh-session'));
      expect(store.items.single.id, 'fresh-session');
    } finally {
      store.dispose();
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
