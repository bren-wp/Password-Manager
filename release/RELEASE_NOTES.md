# Veldigo v0.3.2 Preview 1 — Android + Windows

Verzija aplikacije: **0.3.2+15**. Autor i izdavač: Brendigo.

**Predizdanje.** Nije sigurnosno certificirano ni 100% RGB pixel-perfect. Android APK/AAB se za preview potpisuju razvojnim ključem; nisu namijenjeni produkcijskom Google Play ažuriranju. Windows EXE nema Authenticode potpis.

## Sigurnost i privatnost

- Osam ključnih operacija trezora veže se uz otključanu sesiju **u trenutku poziva**, a ne tek kada dođu na red u asinkronom izvršavanju. Stare ili zaključane radnje ne nasljeđuju prava kasnijeg otključavanja.
- Uklonjena je utrka zastarjelih upisa, brisanja, izvoza, vraćanja kopije i promjene glavne lozinke nakon zaključavanja.
- Jedinstveno upravljanje međuspremnikom za lozinke, generator i TOTP: ograničeno trajanje, čišćenje nakon zaključavanja, zaštita od završetka asinkronog kopiranja nakon zaključavanja.
- Kopiranje tajne ne bi smjelo brisati naknadno promijenjen, nepovezan međuspremnik.
- Zadržani su lokalni **AES-256-GCM** i **Argon2id** te postojeći format .veldigo datoteke. Bez online sinkronizacije i promjena u shemi trezora.
- Dodani automatizirani regresijski testovi za svih osam radnji i utrke međuspremnika.

## UI i platforme

- Zadržane prethodne Android/Windows dorade generatora, zaključavanja, tipografije i zaštite tipkovnice.
- Android: target API 36, minSdk 24, Gradle 9.6.0, Android Gradle Plugin 9.5.0.
- Sadržaj: Android APK/AAB, Windows portable EXE, Setup EXE i ZIP, SHA256 kontrolni zbrojevi.

## Kontrola kvalitete

Izdanje se objavljuje samo ako uspiju analizator, Flutter testovi (uključujući lokalnu enkripciju), Android i Windows release build, te SHA-256 provjera.

## Preostala ograničenja

**26/26 izvornih referentnih dimenzija odgovaralo je testnim snimkama, ali 0/26 zaslona nije potvrđeno RGB-identično.** Za kompletan vizualni 1:1 trebaju pojedinačne dorade, nativni screenshotovi, više DPI postavki i testiranje na stvarnim uređajima. Operacijski sustav može ograničiti pristup međuspremniku u pozadini pa automatsko čišćenje nije apsolutno jamstvo.
