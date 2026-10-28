import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/ui/brand.dart';

void main() {
  testWidgets('Veldigo brand renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: const Scaffold(body: VeldigoLogo()),
    ));
    expect(find.text('VELDIGO'), findsOneWidget);
  });
}
