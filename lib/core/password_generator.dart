import 'dart:math';

class PasswordGenerator {
  static const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const lower = 'abcdefghijkmnopqrstuvwxyz';
  static const digits = '23456789';
  static const symbols = '!@#\$%&*?-_+=';

  static const fullUpper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const fullLower = 'abcdefghijklmnopqrstuvwxyz';
  static const fullDigits = '0123456789';

  static String generate({
    int length = 20,
    bool uppercase = true,
    bool lowercase = true,
    bool numbers = true,
    bool special = true,
    bool avoidSimilar = true,
  }) {
    // Preserve the existing password defaults for backwards compatibility.
    // The UI switch only expands the character alphabet; it never alters
    // existing vault entries or any cryptographic persistence format.
    final pools = <String>[
      if (uppercase) (avoidSimilar ? upper : fullUpper),
      if (lowercase) (avoidSimilar ? lower : fullLower),
      if (numbers) (avoidSimilar ? digits : fullDigits),
      if (special) symbols,
    ];
    if (pools.isEmpty) {
      throw ArgumentError('Odaberite barem jednu skupinu znakova.');
    }
    if (length < pools.length || length > 128 || length < 8) {
      throw ArgumentError('Duljina lozinke nije valjana.');
    }
    final random = Random.secure();
    final result = <String>[];
    for (final pool in pools) {
      result.add(pool[random.nextInt(pool.length)]);
    }
    final all = pools.join();
    while (result.length < length) {
      result.add(all[random.nextInt(all.length)]);
    }
    for (var i = result.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }
    return result.join();
  }
}
