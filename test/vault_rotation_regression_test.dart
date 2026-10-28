import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';

void main() {
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('veldigo-rotation-');
  });
  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  VaultItem entry(int number) => VaultItem(
        id: 'item-$number',
        kind: ItemKind.password,
        title: 'Account $number',
        secret: 'Unique secret $number',
        updatedAt: DateTime.utc(2026, 10, 28),
      );

  test('parallel saves keep every account after relaunch', () async {
    final file = File('${temp.path}/vault.veldigo');
    final vault = VaultStore(vaultFileOverride: file);
    await vault.initialize();
    await vault.create('long and unique master password');
    await Future.wait(List.generate(12, (i) => vault.put(entry(i))));
    vault.lock();
    final relaunched = VaultStore(vaultFileOverride: file);
    await relaunched.initialize();
    await relaunched.unlock('long and unique master password');
    expect(relaunched.items.length, 12);
    expect(relaunched.items.map((item) => item.id).toSet().length, 12);
    expect(relaunched.items.map((item) => item.secret).toSet().length, 12);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('master password rotation retains records and rejects old key', () async {
    final file = File('${temp.path}/vault.veldigo');
    final vault = VaultStore(vaultFileOverride: file);
    await vault.initialize();
    await vault.create('the original long master passphrase');
    await vault.put(entry(1));
    await vault.put(entry(2));
    await vault.changeMasterPassword(
      'the original long master passphrase', 'the updated long master passphrase');
    vault.lock();
    await expectLater(vault.unlock('the original long master passphrase'),
        throwsA(isA<VaultAuthenticationException>()));
    await vault.unlock('the updated long master passphrase');
    expect(vault.items.map((entry) => entry.id).toSet(),
        {'item-1', 'item-2'});
    final files = temp.listSync().map((e) => e.path);
    expect(files.any((e) => e.contains('before-password-change')), isTrue);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('simultaneous first-run creation never silently replaces a vault',
      () async {
    final file = File('${temp.path}/shared-first-run.vault');
    final first = VaultStore(vaultFileOverride: file);
    final second = VaultStore(vaultFileOverride: file);
    await Future.wait([first.initialize(), second.initialize()]);
    final outcome = await Future.wait([
      first.create('first master password unique').then((_) => true,
        onError: (Object _, StackTrace __) => false),
      second.create('second master password unique').then((_) => true,
        onError: (Object _, StackTrace __) => false),
    ]);
    expect(outcome.where((success) => success).length, 1);
    first.lock();
    second.lock();
    final opened = VaultStore(vaultFileOverride: file);
    await opened.initialize();
    await opened.unlock(outcome.first
        ? 'first master password unique' : 'second master password unique');
    expect(opened.hasVault, isTrue);
    await expectLater(opened.create('do not overwrite existing vault'),
        throwsA(isA<StateError>()));
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('second open instance cannot overwrite accounts from first', () async {
    final path = File('${temp.path}/parallel-instances.vault');
    final first = VaultStore(vaultFileOverride: path);
    await first.initialize();
    await first.create('a sufficiently long master password');
    await first.put(entry(10));

    final second = VaultStore(vaultFileOverride: path);
    await second.initialize();
    await second.unlock('a sufficiently long master password');

    await first.put(entry(11));
    await expectLater(second.put(entry(12)),
        throwsA(isA<VaultConflictException>()));

    final reopened = VaultStore(vaultFileOverride: path);
    await reopened.initialize();
    await reopened.unlock('a sufficiently long master password');
    expect(reopened.items.map((x) => x.id).toSet(),
        {'item-10', 'item-11'});
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('tampered encrypted import never destroys existing account', () async {
    final file = File('${temp.path}/vault.veldigo');
    final vault = VaultStore(vaultFileOverride: file);
    await vault.initialize();
    await vault.create('a secret master password 2026');
    await vault.put(entry(8));
    final bytes = await vault.encryptedBackup();
    final damaged = List<int>.from(bytes);
    damaged[damaged.length ~/ 2] ^= 1;
    await expectLater(
      vault.restore(damaged, 'a secret master password 2026'),
      throwsA(isA<Exception>()));
    vault.lock();
    await vault.unlock('a secret master password 2026');
    expect(vault.items.single.id, 'item-8');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
