// Offline end-to-end crypto smoke test using the actual Veldigo vault engine.
// Never accepts a password on the command line or writes decrypted records.
// Run: flutter test test/local_crypto_smoke_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';

void main() {
  test('encrypted vault round-trip, backup migration and tamper detection', () async {
  final directory = await Directory.systemTemp.createTemp('veldigo-crypto-');
  final random = Random.secure();
  String nonce() => base64UrlEncode(
        List<int>.generate(32, (_) => random.nextInt(256)),
      );
  final master = nonce();
  final wrongMaster = nonce();
  final testSecret = nonce();
  final primary = VaultStore(
      vaultFileOverride: File('${directory.path}/primary.veldigo'));
  final imported = VaultStore(
      vaultFileOverride: File('${directory.path}/imported.veldigo'));
  final rejected = VaultStore(
      vaultFileOverride: File('${directory.path}/rejected.veldigo'));
  try {
    await primary.initialize();
    await primary.create(master);
    await primary.put(VaultItem(
      id: 'offline-smoke',
      kind: ItemKind.password,
      title: 'Offline smoke test',
      secret: testSecret,
      updatedAt: DateTime.now().toUtc(),
    ));
    final encrypted = await primary.encryptedBackup();
    if (utf8.decode(encrypted).contains(testSecret)) {
      throw StateError('Plaintext leaked into encrypted vault file.');
    }

    primary.lock();
    await primary.unlock(master);
    if (primary.items.single.secret != testSecret) {
      throw StateError('Local AES-GCM round-trip failed.');
    }
    primary.lock();

    await imported.initialize();
    await imported.importFirstVault(encrypted, master);
    if (imported.items.single.secret != testSecret) {
      throw StateError('Cross-install encrypted backup import failed.');
    }
    imported.lock();

    await rejected.initialize();
    var wrongPasswordRejected = false;
    try {
      await rejected.importFirstVault(encrypted, wrongMaster);
    } catch (_) {
      wrongPasswordRejected = true;
    }
    if (!wrongPasswordRejected || rejected.hasVault) {
      throw StateError('Wrong passphrase was not rejected safely.');
    }

    // Flip a bit in the authenticated tag without modifying the format.
    final envelope = jsonDecode(utf8.decode(encrypted))
        as Map<String, dynamic>;
    final mac = base64Decode(envelope['mac'] as String);
    mac[0] ^= 1;
    envelope['mac'] = base64Encode(mac);
    final tampered = utf8.encode(jsonEncode(envelope));

    var tamperingRejected = false;
    try {
      await rejected.importFirstVault(tampered, master);
    } catch (_) {
      tamperingRejected = true;
    }
    if (!tamperingRejected || rejected.hasVault) {
      throw StateError('Tampered AES-GCM tag was not rejected.');
    }

    expect(imported.hasVault, isTrue);
  } finally {
    primary.dispose();
    imported.dispose();
    rejected.dispose();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
