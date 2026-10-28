import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/ui/encrypted_backup_input.dart';

void main() {
  test('rejects oversized declared file before trying to read it', () async {
    final file = PlatformFile(name: 'oversized.veldigo',
      size: EncryptedBackupInput.maxBytes + 1);
    await expectLater(EncryptedBackupInput.read(file), throwsFormatException);
  });

  test('reads only the local encrypted backup chosen by user', () async {
    final dir = await Directory.systemTemp.createTemp('veldigo-backup-read-');
    try {
      final file = File('${dir.path}/backup.veldigo');
      await file.writeAsString('encrypted-only-test-data', flush: true);
      final selection = PlatformFile(name: 'backup.veldigo',
        size: await file.length(), path: file.path);
      expect(String.fromCharCodes(await EncryptedBackupInput.read(selection)),
        'encrypted-only-test-data');
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('rejects missing selected file without allocating unbounded bytes',
      () async {
    final file = PlatformFile(name: 'missing.veldigo', size: 5);
    await expectLater(EncryptedBackupInput.read(file), throwsFormatException);
  });
}
