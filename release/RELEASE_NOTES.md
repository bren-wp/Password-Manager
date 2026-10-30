# Veldigo v0.3.3 Preview 1 — Android & Windows

**Izdavač:** Brendigo. **Verzija aplikacije:** `0.3.3+16`.
**Status:** Preview, nije produkcijsko sigurnosno certificirano izdanje.

## Popravci funkcionalnosti

- Ispravljena pogreška u UI rukovanju kada operacijski sustav odbije pristup međuspremniku: kopiranje spremljenih lozinki i generiranih lozinki ne uzrokuje neobrađenu grešku.
- Autentifikator razlikuje **nevaljan Base32 TOTP ključ** od **neuspjelog kopiranja u međuspremnik**. Ispravan TOTP ne prikazuje obmanjujuću poruku o ključu ako je OS međuspremnik nedostupan.
- Novi Flutter widget testovi simuliraju OS odbijanje pristupa međuspremniku za generator i TOTP; provjeravaju prikaz korisne poruke i nastavak rada generatora.
- Zadržan je raniji popravak Android generatora: primarni gumb je iznad donje navigacije, postavke su scrollabilne, provjereno na 320×640, 393×852 i 480×900.
- Zadržani su sigurnosni popravci trezora: radnje su vezane za izvornu otključanu sesiju, a lokalno kopirane tajne imaju vremensko ograničenje te se pokušavaju očistiti pri zaključavanju.

## Build, privatnost i kompatibilnost

- Ažuriran GitHub Actions checkout na sigurniju verziju koja koristi Node 24 i ne pohranjuje vjerodajnice u Git konfiguraciju. Android i Windows CI buildovi ostaju odvojeni.
- Flutter CI: 3.47.8; Gradle 9.6.0; AGP 9.5.0; Android target SDK 36, min SDK 24.
- AES-256-GCM + Argon2id i `.veldigo` format ostaju nepromijenjeni: **nije potrebna migracija trezora**.
- Bez vanjskog servisa za lozinke ili izmjena u politici lokalnog spremanja.

## Artefakti

`Veldigo-Android.apk`, `Veldigo-Android.aab`, `Veldigo-portable.exe`, `Veldigo-Setup.exe`, `Veldigo-Windows-portable.zip`, `Android-SHA256.txt`, `Windows-SHA256.txt`.

## Ograničenja za produkciju

- Android AAB koristi razvojni Preview potpis; za Google Play treba izvorni upload keystore, kojega release workflow nema.
- Windows EXE i instalacijski paket nemaju Authenticode potpis.
- 26 od 26 referentnih zaslona ima uparene fizičke dimenzije, ali **0 od 26 nije dokazano potpuno RGB pixel-identično**. Flutter widget snimke nisu zamjena za nativne uređaje i provjeru DPI-ja.
- Međuspremnik je kontroliran od operacijskog sustava pa se apsolutno automatsko brisanje ne može jamčiti.
- Izdanje se objavljuje samo nakon uspješne analize, testova, Android/Windows buildova i provjere SHA-256 kontrolnih zbrojeva.
