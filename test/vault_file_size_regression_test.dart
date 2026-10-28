import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_store.dart';

void main() {
  test('reject oversized local ciphertext without allocating the whole file',
      () async {
    final temp = await Directory.systemTemp.createTemp('veldigo-file-limit-');
    try {
      final file = File('${temp.path}/large.vault');
      final stream = await file.open(mode: FileMode.write);
      try {
        await stream.truncate(64 * 1024 * 1024 + 1);
      } finally {
        await stream.close();
      }
      final store = VaultStore(vaultFileOverride: file);
      await store.initialize();
      expect(store.hasVault, isTrue);
      await expectLater(
        store.unlock('a long master password that should never be needed'),
        throwsA(isA<VaultAuthenticationException>()),
      );
      expect(store.isUnlocked, isFalse);
      // Never delete, truncate or replace a suspicious vault on failed auth.
      expect(await file.length(), 64 * 1024 * 1024 + 1);
    } finally {
      if (await temp.exists()) await temp.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 1)));
}
