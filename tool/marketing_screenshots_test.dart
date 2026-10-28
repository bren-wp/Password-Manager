// Screenshot generator for the actual Flutter widgets used by Veldigo.
// Invoke explicitly: flutter test --update-goldens tool/marketing_screenshots_test.dart
// This is intentionally outside test/ so regular CI does not compare the
// random password generator and TOTP timers against static image goldens.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veldigo/core/vault_item.dart';
import 'package:veldigo/core/vault_store.dart';
import 'package:veldigo/ui/auth_screen.dart';
import 'package:veldigo/ui/brand.dart';
import 'package:veldigo/ui/entry_editor.dart';
import 'package:veldigo/ui/splash_screen.dart';
import 'package:veldigo/ui/vault_shell.dart';
import 'package:veldigo/ui/welcome_screen.dart';

const captureKey = ValueKey('actual-app-screenshot');

// Target physical pixel dimensions measured from the user's supplied PNG
// references. A matching screenshot size is necessary, but not sufficient,
// for pixel-perfect parity. Flutter still requires design-by-design review.
const androidReferencePixels = <String, Size>{
  '01_Glavni_trezor': Size(843, 1866),
  '02_Postavljanje_glavne_lozinke': Size(887, 1774),
  '03_Otkljucavanje': Size(887, 1774),
  '04_Dodavanje_lozinke': Size(864, 1821),
  '05_Detalji_lozinke': Size(862, 1824),
  '06_Generator_lozinki': Size(887, 1774),
  '07_Sigurnosni_centar': Size(841, 1870),
  '08_Sigurne_biljeske': Size(887, 1774),
  '09_Autentifikator_TOTP': Size(862, 1825),
  '10_Postavke': Size(863, 1823),
  '11_Kategorije': Size(832, 1856),
  '12_Sigurnosna_kopija': Size(832, 1856),
  '13_Kartice': Size(832, 1856),
  '14_Uvodni_ekran': Size(832, 1856),
  '15_Dobrodoslica': Size(832, 1856),
};

const windowsReferencePixels = <String, Size>{
  '01_Glavni_trezor': Size(1586, 992),
  '02_Otkljucavanje': Size(1586, 992),
  '03_Dodavanje_lozinke': Size(1586, 992),
  '04_Generator_lozinki': Size(1586, 992),
  '05_Sigurnosni_centar': Size(1536, 1024),
  '06_Sigurne_biljeske': Size(1536, 1024),
  '07_Postavke': Size(1536, 1024),
  '08_Sigurnosna_kopija': Size(1536, 1024),
  '09_Autentifikator': Size(1536, 1024),
  '10_Kategorije': Size(1536, 1024),
  '11_Prvo_postavljanje': Size(1536, 1024),
};

Future<({Directory dir, VaultStore store})> createDemoVault() async {
  final dir = await Directory.systemTemp.createTemp('veldigo-screenshot-');
  final store = VaultStore(vaultFileOverride: File('${dir.path}/vault'));
  await store.initialize();
  await store.create('demo-only-master-passphrase-2026');
  final t = DateTime.utc(2026, 10, 28, 12);
  final examples = [
    VaultItem(id: '01-github', kind: ItemKind.password,
      title: 'GitHub', username: 'demo@example.test',
      secret: 'DEMO-ONLY-sample-password-1', category: 'Posao',
      website: 'https://github.com', favorite: true, updatedAt: t),
    VaultItem(id: '02-google', kind: ItemKind.password,
      title: 'Google', username: 'demo@example.test',
      secret: 'DEMO-ONLY-sample-password-2', category: 'Osobno',
      updatedAt: t),
    VaultItem(id: '03-office', kind: ItemKind.password,
      title: 'Microsoft', username: 'sample@example.test',
      secret: 'DEMO-ONLY-sample-password-3', category: 'Posao',
      updatedAt: t),
    VaultItem(id: '04-tv', kind: ItemKind.password,
      title: 'Netflix', username: 'sample@example.test',
      secret: 'DEMO-ONLY-sample-password-4', category: 'Zabava',
      updatedAt: t),
    VaultItem(id: '05-note', kind: ItemKind.note,
      title: 'Važna bilješka', notes: 'Ovo je samo primjer bilješke.',
      category: 'Osobno', updatedAt: t),
    VaultItem(id: '06-card', kind: ItemKind.card,
      title: 'Demo kartica', username: 'DEMO USER',
      secret: '4111111111111111', expiry: '12/28', cvv: '123',
      category: 'Financije', updatedAt: t),
    VaultItem(id: '07-totp', kind: ItemKind.totp,
      title: 'Demo autentifikator', username: 'demo@example.test',
      secret: 'JBSWY3DPEHPK3PXP', updatedAt: t),
  ];
  for (final item in examples) {
    await store.put(item);
  }
  return (dir: dir, store: store);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> snap(WidgetTester tester, String platform, String file,
      Widget screen, Size size, {double pixelRatio = 1}) async {
    // Golden screenshots use logical pixels even when view DPR > 1.
    // Capture a real full-size PNG using a constrained logical app viewport,
    // then let Flutter paint that viewport into the physical reference size.
    // This keeps mobile navigation/layout while preserving actual PNG pixels.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.pumpWidget(RepaintBoundary(
      key: captureKey,
      child: LayoutBuilder(builder: (context, bounds) => FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: bounds.maxWidth / pixelRatio,
          height: bounds.maxHeight / pixelRatio,
          child: MaterialApp(
            // Navigator's initial home route is not replaced merely because
            // a different home widget is passed on the next pumpWidget.
            // A new application key isolates every screenshot's navigator.
            key: ValueKey('capture-$platform-$file'),
            debugShowCheckedModeBanner: false,
            theme: veldigoTheme(),
            // WidgetsApp derives its default MediaQuery from the physical
            // test view. Override it for every route (including dialogs)
            // so responsive widgets see the *logical* mobile viewport.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(bounds.maxWidth / pixelRatio,
                    bounds.maxHeight / pixelRatio),
                devicePixelRatio: pixelRatio,
              ),
              child: child!,
            ),
            home: KeyedSubtree(key: ValueKey(file), child: screen),
          ),
        ),
      )),
    ));
    await tester.pump(const Duration(milliseconds: 350));
    await expectLater(find.byKey(captureKey),
      matchesGoldenFile('goldens/marketing/$platform/$file.png'));
  }

  testWidgets('capture all 15 Android views from actual Flutter widgets',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final demo = await tester.runAsync(createDemoVault);
    if (demo == null) throw StateError('Demo trezor nije dostupan.');
    addTearDown(() async {
      demo.store.lock();
      if (await demo.dir.exists()) await demo.dir.delete(recursive: true);
    });
    Future<void> shot(String filename, Widget screen) =>
      snap(tester, 'android', filename, screen,
        androidReferencePixels[filename]!, pixelRatio: 2);

    await shot('01_Glavni_trezor', VaultShell(store: demo.store));
    // Details are opened exactly as in the running Android UI.
    await tester.tap(find.text('GitHub').first);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Korisničko ime'), findsOneWidget);
    expect(find.text('Uredi'), findsWidgets);
    // This screen uses its own reference size, not the home screen's.
    tester.view.physicalSize =
        androidReferencePixels['05_Detalji_lozinke']!;
    await tester.pumpAndSettle();
    await expectLater(find.byKey(captureKey),
      matchesGoldenFile('goldens/marketing/android/05_Detalji_lozinke.png'));


    await shot('02_Postavljanje_glavne_lozinke',
      AuthScreen(store: demo.store, create: true));
    expect(find.text('Stvorite sigurni trezor'), findsOneWidget);
    await shot('03_Otkljucavanje',
      AuthScreen(store: demo.store, create: false));
    expect(find.text('Dobro došli natrag'), findsOneWidget);
    await shot('04_Dodavanje_lozinke',
      const Scaffold(body: Center(child:
        EntryEditor(kind: ItemKind.password))));
    await shot('06_Generator_lozinki',
      VaultShell(store: demo.store, initialPage: 'Generator'));
    await shot('07_Sigurnosni_centar',
      VaultShell(store: demo.store, initialPage: 'Sigurnost'));
    await shot('08_Sigurne_biljeske',
      VaultShell(store: demo.store, initialPage: 'Sigurne bilješke'));
    await shot('09_Autentifikator_TOTP',
      VaultShell(store: demo.store, initialPage: 'Autentifikator'));
    await shot('10_Postavke',
      VaultShell(store: demo.store, initialPage: 'Postavke'));
    await shot('11_Kategorije',
      VaultShell(store: demo.store, initialPage: 'Kategorije'));
    await shot('12_Sigurnosna_kopija',
      VaultShell(store: demo.store, initialPage: 'Sigurnosna kopija'));
    await shot('13_Kartice',
      VaultShell(store: demo.store, initialPage: 'Kartice'));
    await shot('14_Uvodni_ekran', const SplashScreen());
    await shot('15_Dobrodoslica', WelcomeScreen(onStart: () {}));
  }, timeout: const Timeout(Duration(minutes: 6)));

  testWidgets('capture all 11 Windows layout views from real Flutter UI',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final demo = await tester.runAsync(createDemoVault);
    if (demo == null) throw StateError('Demo trezor nije dostupan.');
    addTearDown(() async {
      demo.store.lock();
      if (await demo.dir.exists()) await demo.dir.delete(recursive: true);
    });
    Future<void> shot(String filename, Widget screen) =>
      snap(tester, 'windows', filename, screen,
        windowsReferencePixels[filename]!);
    await shot('01_Glavni_trezor', VaultShell(store: demo.store));
    await shot('02_Otkljucavanje',
      AuthScreen(store: demo.store, create: false));
    await shot('03_Dodavanje_lozinke',
      const Scaffold(body: Center(child:
        EntryEditor(kind: ItemKind.password))));
    await shot('04_Generator_lozinki',
      VaultShell(store: demo.store, initialPage: 'Generator'));
    await shot('05_Sigurnosni_centar',
      VaultShell(store: demo.store, initialPage: 'Sigurnost'));
    await shot('06_Sigurne_biljeske',
      VaultShell(store: demo.store, initialPage: 'Sigurne bilješke'));
    await shot('07_Postavke',
      VaultShell(store: demo.store, initialPage: 'Postavke'));
    await shot('08_Sigurnosna_kopija',
      VaultShell(store: demo.store, initialPage: 'Sigurnosna kopija'));
    await shot('09_Autentifikator',
      VaultShell(store: demo.store, initialPage: 'Autentifikator'));
    await shot('10_Kategorije',
      VaultShell(store: demo.store, initialPage: 'Kategorije'));
    await shot('11_Prvo_postavljanje',
      AuthScreen(store: demo.store, create: true));
  }, timeout: const Timeout(Duration(minutes: 6)));
}
