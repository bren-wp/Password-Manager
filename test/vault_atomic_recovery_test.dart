import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_files.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';

void main() {
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('veldigo-recovery-');
  });
  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('verified recovery restores the exact chosen ciphertext', () async {
    final target = File('${temp.path}/recover.vault');
    final store = VaultStore(vaultFileOverride: target);
    await store.initialize();
    const password = 'a strong unique master passphrase';
    await store.create(password);
    await store.put(VaultItem(
      id: 'old', kind: ItemKind.password, title: 'First account',
      secret: 'first-secret', updatedAt: DateTime.utc(2026, 10, 28),
    ));
    final oldVersion = await store.encryptedBackup();
    await store.put(VaultItem(
      id: 'new', kind: ItemKind.password, title: 'Second account',
      secret: 'second-secret', updatedAt: DateTime.utc(2026, 10, 28),
    ));
    final newestVersion = await store.encryptedBackup();

    // Simulate power loss leaving different valid versions on disk.
    store.lock();
    await target.delete();
    final files = VaultFiles(target, verify: (bytes) async =>
        bytes.isNotEmpty && utf8.decode(bytes).contains('cipherText'));
    await files.swap.writeAsBytes(oldVersion, flush: true);
    await files.pending.writeAsBytes(newestVersion, flush: true);

    final reopened = VaultStore(vaultFileOverride: target);
    await reopened.initialize();
    await reopened.unlock(password);
    final persisted = await reopened.encryptedBackup();
    expect(persisted, oldVersion);
    expect(reopened.items.map((record) => record.id).toSet(), {'old'});
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('existing valid recovery stage is never silently overwritten',
      () async {
    final target = File('${temp.path}/guarded.vault');
    final files = VaultFiles(target, verify: (bytes) async =>
        utf8.decode(bytes).startsWith('AUTH:'));
    await files.recoveryStage.writeAsString('AUTH:newer', flush: true);
    await expectLater(
      files.restoreExactWhenMissing(utf8.encode('AUTH:older')),
      throwsA(isA<FileSystemException>()));
    expect(await files.recoveryStage.readAsString(), 'AUTH:newer');
    expect(await target.exists(), isFalse);
    await files.restoreExactWhenMissing(utf8.encode('AUTH:newer'));
    expect(await target.readAsString(), 'AUTH:newer');
    expect(await files.recoveryStage.exists(), isFalse);
  });

  test('damaged temporary restore cannot block verified backup recovery',
      () async {
    final target = File('${temp.path}/resume.vault');
    final files = VaultFiles(target, verify: (bytes) async =>
        utf8.decode(bytes).startsWith('AUTH:'));
    await files.recoveryStage.writeAsString('damaged checkpoint', flush: true);
    await files.swap.writeAsString('AUTH:committed', flush: true);
    await files.recoverInterruptedReplacement();
    expect(await target.readAsString(), 'AUTH:committed');
    expect(temp.listSync().any((file) =>
      file.path.contains('.recovery-corrupt-')), isTrue);
  });

  test('recovery never overwrites a primary created by another instance',
      () async {
    final target = File('${temp.path}/concurrent.vault');
    final files = VaultFiles(target, verify: (bytes) async =>
        utf8.decode(bytes).startsWith('AUTH:'));
    await target.writeAsString('AUTH:committed', flush: true);
    await expectLater(
      files.restoreExactWhenMissing(utf8.encode('AUTH:old')),
      throwsA(isA<FileSystemException>()));
    expect(await target.readAsString(), 'AUTH:committed');
  });

  test('a corrupted recovery candidate never creates an empty vault', () async {
    final target = File('${temp.path}/broken.vault');
    await File('${target.path}.swap')
        .writeAsString('not an encrypted vault', flush: true);
    final store = VaultStore(vaultFileOverride: target);
    await store.initialize();
    expect(store.hasVault, isTrue);
    await expectLater(store.unlock('some master password'),
        throwsA(isA<VaultAuthenticationException>()));
    expect(await target.exists(), isFalse);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
