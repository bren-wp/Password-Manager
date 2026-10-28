import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/password_generator.dart';

void main() {
  test('generator uses requested length and all enabled groups', () {
    for (var i = 0; i < 30; i++) {
      final value = PasswordGenerator.generate(length: 32);
      expect(value.length, 32);
      expect(value.contains(RegExp(r'[A-Z]')), isTrue);
      expect(value.contains(RegExp(r'[a-z]')), isTrue);
      expect(value.contains(RegExp(r'[0-9]')), isTrue);
      expect(value.contains(RegExp(r'[^A-Za-z0-9]')), isTrue);
    }
  });

  test('generator refuses empty character sets', () {
    expect(() => PasswordGenerator.generate(
      uppercase: false, lowercase: false,
      numbers: false, special: false), throwsArgumentError);
  });

  test('generator honors only-number mode', () {
    final value = PasswordGenerator.generate(length: 16,
      uppercase: false, lowercase: false,
      numbers: true, special: false);
    expect(value.length, 16);
    expect(RegExp(r'^[0-9]+$').hasMatch(value), isTrue);
  });
}
