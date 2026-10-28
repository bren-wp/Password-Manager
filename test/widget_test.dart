import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/ui/brand.dart';

void main() {
  testWidgets('Veldigo branding is accessible', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: const Scaffold(body: Center(child: VeldigoLogo())),
    ));
    expect(find.text('VELDIGO'), findsOneWidget);
  });
}
