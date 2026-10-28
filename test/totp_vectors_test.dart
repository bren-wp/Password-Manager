import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/totp.dart';

void main() {
  const rfcSecret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

  test('TOTP matches RFC 6238 SHA-1 vectors, shortened to six digits', () async {
    expect(await Totp.generate(rfcSecret, 59), '287082');
    expect(await Totp.generate(rfcSecret, 1111111109), '081804');
    expect(await Totp.generate(rfcSecret, 1111111111), '050471');
    expect(await Totp.generate(rfcSecret, 1234567890), '005924');
    expect(await Totp.generate(rfcSecret, 2000000000), '279037');
    expect(await Totp.generate(rfcSecret, 20000000000), '353130');
  });

  test('Base32 rejects invalid character, excess size and nonzero trailing bits', () {
    expect(() => Totp.decodeBase32('%%%'), throwsFormatException);
    expect(() => Totp.decodeBase32('A'.padRight(4097, 'A')), throwsFormatException);
    expect(() => Totp.decodeBase32('MZ'), throwsFormatException);
    expect(Totp.decodeBase32('MZXW6==='), [102, 111, 111]);
    expect(() => Totp.decodeBase32(''), throwsFormatException);
    expect(() => Totp.decodeBase32('A'), throwsFormatException);
  });
}
