# Veldigo v0.3.5 Preview 1 — Android UI i provjere trezora

**Verzija:** `0.3.5+18` · **Tag:** `v0.3.5-preview.1` · **Izdanje:** Preview za testiranje.

## Android — redom kroz zaslone

- **Uvodni ekran (Splash):** obnovljeni gradijent i Veldigo vektorski štit prema izvornom Android PNG-u; prilagodba kratkim uređajima i velikoj tipografiji. Stvarna inicijalizacija prikazuje neodređeno učitavanje umjesto lažnog stalnog 58%.
- **Dobrodošlica:** preuređeni razmaci, oznaka, tamna pozadina, sadržaj kartice, indikator stranica i primarna strelica desno. `Započni` i `Uvezite kopiju` ostaju potpuno odvojene radnje.
- **Postavljanje glavne lozinke:** poravnani raspored naslova i opisa, viša polja za dodir, čitljiviji indikator jačine i pravila, primarni gumb sa strelicom desno te kompaktna radnja za stvarni uvoz šifrirane kopije.
- Dodatni regresijski testovi za Android zaslone raznih veličina, povećan tekst, razdvojenu vidljivost lozinki, unos potvrde te validaciju.

## Sigurnost

- Minimalna duljina nove glavne lozinke **12 znakova**, bez snižavanja na 8 znakova iz dizajnerske makete.
- Nisu mijenjani AES-256-GCM, Argon2id, format trezora, korisničke tajne i postupci sigurnosne kopije.
- Ne postoji nesiguran reset zaboravljene glavne lozinke niti lažno biometrijsko otključavanje.

## Dostavljene datoteke

Kad release workflow prođe, na ovom tagu objavljuju se:
- `Veldigo-Android.apk` i `Veldigo-Android.aab`
- `Veldigo-portable.exe`, `Veldigo-Setup.exe` i `Veldigo-Windows-portable.zip`
- `Android-SHA256.txt` i `Windows-SHA256.txt`

## Ograničenja Preview izdanja

**Važno:** Android release preview koristi razvojni potpis kada produkcijski upload keystore nije povezan. Takav AAB **nije prikladan za nadogradnju postojeće Google Play aplikacije** i ne smije se objavljivati kao Play-potpisano produkcijsko izdanje. Windows EXE/Setup nema Authenticode potpis.

Vizualna podudarnost s originalnim referentnim PNG-ovima još se dorađuje. **Nije potvrđena RGB 1:1 podudarnost ni 0% odstupanja.** Broj referentnih piksela, položaj Android sistemskih traka i razlike stvarnog renderera utječu na mjerenja.

Objava je automatski uvjetovana prolazom `flutter analyze`, `flutter test`, lokalnih kriptografskih testova, Android release APK/AAB i Windows buildova te SHA-256 provjera.
