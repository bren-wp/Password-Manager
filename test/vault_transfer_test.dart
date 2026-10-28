import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';

void main() {
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('veldigo-transfer-test-');
  });
  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('new Android/Windows install can import encrypted backup without loss',
      () async {
    final oldFile = File('${temp.path}/old-vault');
    final original = VaultStore(vaultFileOverride: oldFile);
    await original.initialize();
    await original.create('the master passphrase of old device');
    await original.put(VaultItem(
      id: 'saved-account', kind: ItemKind.password,
      title: 'Important account', username: 'name@example.test',
      secret: 'confidential password',
      updatedAt: DateTime.utc(2026, 10, 28),
    ));
    final backup = await original.encryptedBackup();
    final destination = VaultStore(vaultFileOverride:
      File('${temp.path}/new-device-vault'));
    await destination.initialize();
    expect(destination.hasVault, isFalse);
    await destination.importFirstVault(
      backup, 'the master passphrase of old device');
    expect(destination.hasVault, isTrue);
    expect(destination.items.single.secret, 'confidential password');
    destination.lock();
    await destination.unlock('the master passphrase of old device');
    expect(destination.items.single.id, 'saved-account');

    // Even the same valid backup may never overwrite existing local state.
    await expectLater(
      destination.importFirstVault(backup, 'the master passphrase of old device'),
      throwsA(isA<StateError>()));
    expect(destination.items.single.title, 'Important account');
  }, timeout: const Timeout(Duration(minutes: 4)));

  test('malformed first-run import never creates a phantom empty vault',
      () async {
    final destination = VaultStore(vaultFileOverride:
      File('${temp.path}/new-device-vault'));
    await destination.initialize();
    await expectLater(
      destination.importFirstVault([0, 1, 2], 'wrong master password'),
      throwsA(isA<Exception>()));
    expect(destination.hasVault, isFalse);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
