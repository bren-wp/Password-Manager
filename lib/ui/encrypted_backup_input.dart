import 'dart:typed_data';

/// Streams only a user-selected encrypted archive. The cap is enforced on the
/// bytes actually received, even if a provider lies about file size.
class EncryptedBackupInput {
  EncryptedBackupInput._();

  static const maxBytes = 64 * 1024 * 1024;

  static Future<List<int>> read(Stream<List<int>> chunks,
      {int? reportedSize}) async {
    if (reportedSize != null && reportedSize > maxBytes) {
      throw const FormatException('Sigurnosna kopija je prevelika.');
    }
    final result = BytesBuilder(copy: false);
    await for (final chunk in chunks) {
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
