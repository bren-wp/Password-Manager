import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_files.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';

void main() {
  late Directory temp;
  setUp(() async => temp = await Directory.systemTemp.createTemp('veldigo-tests-'));
  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('rotating backups preserve earlier valid data', () async {
    final file = File('${temp.path}/test.vault');
    final files = VaultFiles(file, verify: (bytes) async =>
        utf8.decode(bytes).startsWith('AUTH:'));
    await files.install(utf8.encode('AUTH:one'));
    await files.install(utf8.encode('AUTH:two'));
    await files.install(utf8.encode('AUTH:three'));

    expect(await file.readAsString(), 'AUTH:three');
    expect(await files.previous.readAsString(), 'AUTH:two');
    expect(await files.older.readAsString(), 'AUTH:one');
  });

  test('missing primary is restored from a verified checkpoint', () async {
    final file = File('${temp.path}/test.vault');
    final files = VaultFiles(file, verify: (bytes) async =>
        utf8.decode(bytes).startsWith('AUTH:'));
    await files.install(utf8.encode('AUTH:one'));
    await files.install(utf8.encode('AUTH:two'));
    await file.delete(); // Simulate interrupted replacement.
    await files.recoverInterruptedReplacement();
    expect(await file.readAsString(), 'AUTH:one');
  });

  test('failed validation never replaces a committed vault', () async {
    final file = File('${temp.path}/test.vault');
    final files = VaultFiles(file, verify: (bytes) async =>
        utf8.decode(bytes).startsWith('AUTH:'));
    await files.install(utf8.encode('AUTH:valid'));
    await expectLater(files.install(utf8.encode('broken')), throwsFormatException);
    expect(await file.readAsString(), 'AUTH:valid');
  });

  test('AES-GCM vault round trip, wrong password and recovery copy', () async {
    final file = File('${temp.path}/private.vault');
    final store = VaultStore(vaultFileOverride: file);
    await store.initialize();
    expect(store.hasVault, isFalse);
    await store.create('a long unique master password');
    await store.put(VaultItem(
      id: 'first', kind: ItemKind.password, title: 'GitHub',
      username: 'account@example.com', secret: 'correct horse battery staple',
      updatedAt: DateTime.utc(2026, 10, 28),
    ));
    await store.put(VaultItem(
      id: 'second', kind: ItemKind.password, title: 'Email',
      secret: 'another secret', updatedAt: DateTime.utc(2026, 10, 28),
    ));
    final snapshot = await store.encryptedBackup();
    expect(utf8.decode(snapshot), isNot(contains('correct horse battery staple')));
    expect(await File('${file.path}.bak').exists(), isTrue);
    store.lock();
    await expectLater(store.unlock('wrong pass'), throwsA(
      isA<VaultAuthenticationException>()));
    await store.unlock('a long unique master password');
    expect(store.items.map((e) => e.id), containsAll(['first', 'second']));

    // Silent fallback is prohibited when primary is corrupted: user must
    // explicitly choose to recover an older backup.
    store.lock();
    await file.writeAsString('corrupted file', flush: true);
    await expectLater(store.unlock('a long unique master password'),
        throwsA(isA<VaultAuthenticationException>()));
    await store.recoverFromLocalBackup('a long unique master password');
    expect(store.items.any((e) => e.id == 'first'), isTrue);
    expect(await file.readAsString(), isNot(contains('corrupted file')));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
