import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Reads only an explicitly selected encrypted backup, with an enforced cap
/// even if the provider reports a false size or grows the file during read.
class EncryptedBackupInput {
  EncryptedBackupInput._();

  static const maxBytes = 64 * 1024 * 1024;

  static Future<List<int>> read(PlatformFile selected) async {
    if (selected.size > maxBytes) {
      throw const FormatException('Sigurnosna kopija je prevelika.');
    }
    final path = selected.path;
    if (path == null) {
      final inMemory = selected.bytes;
      if (inMemory == null || inMemory.length > maxBytes) {
        throw const FormatException('Sigurnosnu kopiju nije moguće pročitati.');
      }
      return inMemory;
    }
    final source = File(path);
    if (await source.length() > maxBytes) {
      throw const FormatException('Sigurnosna kopija je prevelika.');
    }
    final result = BytesBuilder(copy: false);
    await for (final chunk in source.openRead(0, maxBytes + 1)) {
      if (result.length + chunk.length > maxBytes) {
        throw const FormatException('Sigurnosna kopija je prevelika.');
      }
      result.add(chunk);
    }
    if (result.length == 0) {
      throw const FormatException('Sigurnosna kopija je prazna.');
    }
    return result.takeBytes();
  }
}
