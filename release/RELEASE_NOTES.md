# Veldigo v0.3.0 Preview 1 — Android + Windows

**Preview izdanje; nije certificirani proizvod niti Google Play produkcijski potpisan AAB.**
Verzija aplikacije: `0.3.0+13`. Autor i izdavač: Brendigo.

## Platforme i build

- Android: Google Play target API 36, minSdk 24, Gradle 9.6.0 i Android Gradle Plugin 9.5.0, JDK 17.
- Flutter 3.47.8 postavljen kao provjerena CI verzija.
- Android nema nešifrirani promet aplikacije, OS backup trezora je isključen i `FLAG_SECURE` štiti osjetljive zaslone od uobičajenog snimanja.
- Release signing: testno/pregledno potpisivanje **izričito označeno preview**. Za Play upload potreban je izdavačev zasebni upload ključ; testni AAB se ne smije slati u produkciju.
- Windows: release desktop izvršna datoteka, prenosivi samostalni program, instalacijski paket i ZIP, bez potvrđenog Authenticode potpisa.

## Sigurnost, stabilnost i privatnost

- Očuvan je postojeći lokalni format trezora: **AES-256-GCM**, Argon2id (19 MiB, t=2, p=1), jedinstvena sol i slučajni nonce te autentifikacija šifriranog sadržaja.
- Nije uvedena nova vlastita kriptografija, mrežna sinkronizacija, telemetrija ili potreba za slanjem lozinki vanjskom servisu.
- Novi lokalni test `flutter test test/local_crypto_smoke_test.dart` provjerava šifriranje/dešifriranje, šifrirani prijenos, odbijanje pogrešne glavne lozinke te izmjenu autentifikacijske oznake.
- Android build skripta više ne prepisuje `MainActivity.kt`; provjerava primjenu `FLAG_SECURE` i SDK razine.
- Provjere `flutter analyze`, `flutter test`, lokalni crypto smoke test i debug/release buildovi uvjetuju objavu.

## UI/UX

- Nastavljene dorade Android i Windows dizajna iz prethodnih spojenih PR-ova #10 i #11, uključujući Windows generator i privatnu, maskiranu povijest generiranja.
- Objavljene Flutter snimke zaslona nisu dokaz stvarnog prikaza u nativnom Windows/Android runtimeu.
- **Nije potvrđeno pixel-perfect RGB 1:1 za 26 referenci.** Preostaju precizni vizualni diffovi, tipografija, različiti DPI-ovi i testovi na fizičkim uređajima.

## Datoteke izdanja

- `Veldigo-Android.apk`, `Veldigo-Android.aab`
- `Veldigo-portable.exe`, `Veldigo-Setup.exe`, `Veldigo-Windows-portable.zip`
- `Android-SHA256.txt`, `Windows-SHA256.txt`

## Preostala ograničenja

Nije izveden nezavisni sigurnosni audit, napadno testiranje, dokaz potpune otpornosti na gubitak napajanja, ni provjera svih Android uređaja i Windows DPI postavki. Rukovanje tajnama u memoriji i sigurnost međuspremnika ovise i o operacijskom sustavu. Nije zajamčena apsolutna sigurnost niti "vojna certifikacija". Neovjereni Windows izvršni programi mogu prikazati SmartScreen upozorenje. Korisnici trebaju čuvati neovisne šifrirane sigurnosne kopije.
