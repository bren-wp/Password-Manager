import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/extra_pages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        throw PlatformException(code: 'clipboard_unavailable');
      }
      return null;
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('Android generator survives denied clipboard access',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: const Scaffold(body: GeneratorPage()),
    ));
    await tester.tap(find.byTooltip('Kopiraj lozinku'));
    await tester.pumpAndSettle();
    expect(find.text('Međuspremnik nije dostupan. Pokušajte ponovno.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    // Copy failure must not disable generation of a new password.
    await tester.tap(find.text('Generiraj novu lozinku'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('TOTP differentiates invalid key from unavailable clipboard',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final credential = VaultItem(
      id: 'totp-smoke',
      kind: ItemKind.totp,
      title: 'Example local authenticator',
      username: 'user@example.test',
      secret: 'JBSWY3DPEHPK3PXP',
      updatedAt: DateTime.utc(2026, 10, 30),
    );
    await tester.pumpWidget(MaterialApp(
      theme: veldigoTheme(),
      home: Scaffold(
        body: AuthenticatorPage(
          items: [credential],
          onAdd: () {},
        ),
      ),
    ));
    await tester.tap(find.byTooltip('Kopiraj TOTP kod'));
    await tester.pumpAndSettle();
    expect(find.text('Međuspremnik nije dostupan. Pokušajte ponovno.'),
        findsOneWidget);
    expect(find.text('TOTP ključ nije valjan. Provjerite unos.'),
        findsNothing);
    expect(tester.takeException(), isNull);
  });
}
