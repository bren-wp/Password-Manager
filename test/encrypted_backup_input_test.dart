import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/ui/encrypted_backup_input.dart';

void main() {
  test('rejects oversized metadata without consuming the stream', () async {
    var consumed = false;
    Stream<List<int>> source() async* {
      consumed = true;
      yield [1];
    }
    await expectLater(
      EncryptedBackupInput.read(
        source(), reportedSize: EncryptedBackupInput.maxBytes + 1),
      throwsFormatException);
    expect(consumed, isFalse);
  });

  test('reads the selected encrypted backup from a byte stream', () async {
    final chunks = Stream<List<int>>.fromIterable([
      utf8.encode('encrypted-'),
      utf8.encode('only-test-data'),
    ]);
    expect(utf8.decode(await EncryptedBackupInput.read(chunks,
      reportedSize: 24)), 'encrypted-only-test-data');
  });

  test('rejects empty selected archive', () async {
    await expectLater(EncryptedBackupInput.read(
      const Stream<List<int>>.empty()), throwsFormatException);
  });

  test('rejects actual bytes above the cap despite false provider size',
      () async {
    Stream<List<int>> source() async* {
      yield List<int>.filled(EncryptedBackupInput.maxBytes, 0);
      yield [1];
    }
    await expectLater(EncryptedBackupInput.read(source(), reportedSize: 1),
      throwsFormatException);
  }, timeout: const Timeout(Duration(minutes: 1)));
}
