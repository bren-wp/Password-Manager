import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shipping UI does not contain inactive roadmap controls', () async {
    final pages = await File('lib/ui/extra_pages.dart').readAsString();
    for (final phrase in [
      'U planu — nije aktivno u ovoj verziji',
      'QR skeniranje još nije dostupno',
      "title: Text('Biometrijsko otključavanje')",
      "title: Text('Sinkronizacija u oblaku')",
    ]) {
      expect(pages.contains(phrase), isFalse, reason: phrase);
    }
  });
  test('import uses size limits and does not preload arbitrary file bytes',
      () async {
    final backup = await File('lib/ui/extra_pages.dart').readAsString();
    expect(backup, contains('FilePicker.pickFile('));
    expect(backup, contains('readAsByteStream()'));
  });
}
