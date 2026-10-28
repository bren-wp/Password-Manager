import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('veldigo-session-cancel-');
  });
  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  VaultItem entry(String id) => VaultItem(
        id: id,
        kind: ItemKind.password,
        title: id,
        secret: 'test-only-secret-for-$id',
        updatedAt: DateTime.utc(2026, 10, 28),
      );

  test('closing an app session during unlock cannot reopen secrets', () async {
    const password = 'sufficiently long master passphrase test';
    final file = File('${temp.path}/unlock.vault');
    final writer = VaultStore(vaultFileOverride: file);
    await writer.initialize();
    await writer.create(password);
    await writer.put(entry('account'));
    writer.lock();

    final reader = VaultStore(vaultFileOverride: file);
    await reader.initialize();
    final unlocking = reader.unlock(password);
    // Allow the queued operation to enter its async Argon2 derivation.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    reader.lock();
    try {
      await unlocking;
    } on VaultSessionCancelledException {
      // Explicit cancellation is a normal result of user-requested lock.
    } on VaultAuthenticationException {
      // A cancellation may also fail a concurrently verified file read.
    }
    expect(reader.isUnlocked, isFalse);
    expect(reader.items, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('locking while changing the master key cannot resurrect the key',
      () async {
    const original = 'original sufficiently long master passphrase';
    const replacement = 'replacement sufficiently long master passphrase';
    final file = File('${temp.path}/password.vault');
    final store = VaultStore(vaultFileOverride: file);
    await store.initialize();
    await store.create(original);
    await store.put(entry('important'));
    final changing = store.changeMasterPassword(original, replacement);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    store.lock();
    try {
      await changing;
    } on VaultSessionCancelledException {
      // A lock intentionally invalidates in-flight operations.
    } on StateError {
      // Changes may be rejected if the session is already locked.
    }
    expect(store.isUnlocked, isFalse);
    expect(store.items, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('locking during backup import does not resurrect imported secrets',
      () async {
    const original = 'import-source sufficiently long passphrase';
    const replacement = 'destination sufficiently long passphrase';
    final source = VaultStore(
      vaultFileOverride: File('${temp.path}/source.vault'));
    await source.initialize();
    await source.create(original);
    await source.put(entry('imported'));
    final archive = await source.encryptedBackup();

    final destination = VaultStore(
      vaultFileOverride: File('${temp.path}/destination.vault'));
    await destination.initialize();
    await destination.create(replacement);
    final importing = destination.restore(archive, original);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    destination.lock();
    try {
      await importing;
    } on VaultSessionCancelledException {
      // Cancellation is expected if the restore is still in progress.
    } on StateError {
      // Already-locked requests fail closed.
    }
    expect(destination.isUnlocked, isFalse);
    expect(destination.items, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
