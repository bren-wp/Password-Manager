import 'package:cryptography/cryptography.dart';

/// RFC 6238-compatible six-digit SHA-1 TOTP generator. Secrets remain local.
class Totp {
  const Totp._();

  static List<int> decodeBase32(String source) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final input = source.toUpperCase().replaceAll(RegExp(r'[\s=\-]'), '');
    if (input.isEmpty || input.length > 4096) {
      throw const FormatException('Neispravan TOTP tajni ključ.');
    }
    var buffer = 0;
    var bits = 0;
    final result = <int>[];
    for (final character in input.split('')) {
      final digit = alphabet.indexOf(character);
      if (digit < 0) {
        throw const FormatException('Neispravan Base32 ključ.');
      }
      buffer = (buffer << 5) | digit;
      bits += 5;
      while (bits >= 8) {
        bits -= 8;
        result.add((buffer >> bits) & 255);
        buffer &= (1 << bits) - 1;
      }
    }
    if (result.isEmpty || buffer != 0) {
      throw const FormatException('Nepotpun ili neispravan Base32 ključ.');
    }
    return result;
  }

  static Future<String> generate(String source, int epochSeconds) async {
    if (epochSeconds < 0) {
      throw ArgumentError('Vrijeme TOTP koda nije valjano.');
    }
    var counter = epochSeconds ~/ 30;
    final data = List<int>.filled(8, 0);
    for (var i = 7; i >= 0; i--) {
      data[i] = counter & 255;
      counter >>= 8;
    }
    final bytes = (await Hmac.sha1().calculateMac(
      data, secretKey: SecretKey(decodeBase32(source)))).bytes;
    final offset = bytes.last & 0x0f;
    final value = ((bytes[offset] & 0x7f) << 24) |
      ((bytes[offset + 1] & 255) << 16) |
      ((bytes[offset + 2] & 255) << 8) |
      (bytes[offset + 3] & 255);
    return (value % 1000000).toString().padLeft(6, '0');
  }
}
