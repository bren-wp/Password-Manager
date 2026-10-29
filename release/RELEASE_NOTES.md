# Veldigo v0.2.9 Preview 1 — Android + Windows

Veldigo Password Manager za Android i Windows. Ovo je **predizdanje za provjeru** s najnovijim izmjenama uključenima u spojene PR-ove #8 i #9.

## Vizualni identitet i funkcionalnost
- Zajednička tipografija Roboto i usklađeni stilovi gumba, kartica, ikona, margina, zaglavlja i navigacije.
- Android: uređeno zaglavlje s logotipom, donja navigacija, raspored trezora na manjim ekranima, pregled kartica s maskiranim brojem i početni zaslon s dostupnim glavnim akcijama.
- Windows: kompaktniji trezor i tablični prikaz s kategorijama, datumima i funkcionalnim panelom detalja.
- Generator lozinki: odvojeni paneli za generirani rezultat, duljinu 8–128 znakova, skupine znakova, isključivanje sličnih znakova i procjenu jačine.
- Autentifikator: prikaz lokalno generiranog TOTP koda i vremenski ograničen clipboard.
- Sigurnosna kopija: odvojene cjeline za izvoz, vraćanje, prijenos podataka i informacije o privatnosti; format šifrirane `.veldigo` kopije ostaje kompatibilan.
- Detalji zapisa, uređivanje, postavke i sigurnosni centar imaju poboljšana poravnanja, kontrole i responzivnost.

## Sigurnost i pouzdanost
- Zadržan postojeći **AES-256-GCM / Argon2id** format trezora.
- Serijalizirani konkurentni upisi štite od istodobnog prvog stvaranja trezora.
- Regresijski testovi štite od prikaza tajnih podataka nakon zaključavanja i od gubitka nespremljenih unosa.
- Android aplikacija isključuje OS backup podataka trezora i postavlja FLAG_SECURE te minimalni API 24.

## Distribucija
- **Veldigo-Android.apk** — instalacijski APK za Android.
- **Veldigo-Android.aab** — App Bundle, nije potpisan produkcijskim Google Play upload ključem.
- **Veldigo-portable.exe** — Windows prijenosna aplikacija.
- **Veldigo-Setup.exe** — Windows instalacijski program.
- **Veldigo-Windows-portable.zip** — Windows prijenosni paket.
- **Android-SHA256.txt / Windows-SHA256.txt** — kontrolni zbrojevi za provjeru preuzimanja.

## Poznata ograničenja
**Predizdanje.** Sva 26 UI snimka testiraju se na referentnim dimenzijama, ali nije postignuta potpuna pixel-perfect 1:1 podudarnost s referentnim nacrtima. Nema potvrde neovisnog penetracijskog testiranja ili testiranja na fizičkim Android i Windows uređajima. Android AAB nije spreman za distribuciju na Google Playu bez odgovarajućeg izdavačkog potpisa, a nepotpisani Windows izvršni programi mogu aktivirati SmartScreen upozorenja. Ovo izdanje nije certificirana sigurnosna aplikacija.

Nije dodana udaljena sinkronizacija; korisnički trezor i dalje ostaje lokalno šifriran.
