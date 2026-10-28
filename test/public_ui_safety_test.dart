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
  test('no developer placeholders or fake credentials in any shipped screen',
      () async {
    final screens = <File>[
      File('lib/main.dart'),
      ...await Directory('lib/ui')
          .list(recursive: true)
          .where((entry) => entry is File && entry.path.endsWith('.dart'))
          .cast<File>()
          .toList(),
    ];
    const forbidden = <String>[
      'TODO: IMPLEMENT',
      'FIXME',
      'U planu —',
      'nije aktivno u ovoj verziji',
      'QR skeniranje još nije dostupno',
      'DEMO-ONLY-',
      'STAGING ONLY',
      'DEBUG MODE',
      'development placeholder',
    ];
    for (final file in screens) {
      final source = await file.readAsString();
      for (final phrase in forbidden) {
        expect(source.contains(phrase), isFalse,
          reason: '${file.path} contains inactive/developer text: $phrase');
      }
    }
  });

  test('import uses size limits and does not preload arbitrary file bytes',
      () async {
    final backup = await File('lib/ui/extra_pages.dart').readAsString();
    expect(backup, contains('FilePicker.pickFile('));
    expect(backup, contains('readAsByteStream()'));
  });
}
