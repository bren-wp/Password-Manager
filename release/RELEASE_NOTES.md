# Veldigo v0.2.3 — Preview 2

**Još sigurniji oporavak. Privatnost odmah po izlasku.**

## Novo i poboljšano

- Androidov sistemski odabir šifrirane kopije ima vremenski ograničenu iznimku od zaključavanja, a trezor se ponovno štiti po isteku i pri povratku aplikacije.\n- Trezor se zaključava pri prelasku aplikacije u pozadinu,
  bez dvominutnog razdoblja u kojem ostaje otključan.
- Oporavak nakon prekida zapisivanja vraća **točno istu**
  autentificiranu šifriranu datoteku koja je uspješno otključana.
- Zaključavanje datoteke između različitih instanci sprječava
  istodobni oporavak i zamjenu novijeg stanja starijim.
- Datoteke za oporavak spremaju se i provjeravaju prije konačne
  zamjene glavnog trezora.
- Oštećena privremena kopija čuva se za mogući ručni oporavak;
  valjana različita kopija ne zamjenjuje se bez potvrde.
- Dodani testovi za konkurentni oporavak, prekinuti zapis,
  provjeru identiteta šifrirane kopije i obnovu bez gubitka podataka.
- Marketinški README ažuriran je sa svih **26 stvarno renderiranih**
  Veldigo Flutter zaslona (15 Android i 11 Windows rasporeda).

## Datoteke izdanja

- `Veldigo-Android.apk` — Android aplikacija
- `Veldigo-Android.aab` — Android App Bundle
- `Veldigo-portable.exe` — Windows prijenosna aplikacija
- `Veldigo-Setup.exe` — Windows instalacija
- `Veldigo-Windows-portable.zip` — alternativni prijenosni paket
- `Android-SHA256.txt` i `Windows-SHA256.txt` — kontrolni zbrojevi

## Važno za vaše podatke

Ovo je **predizdanje**, a ne neovisno auditirana aplikacija za pohranu
nezamjenjivih lozinki. Niti jedna aplikacija ne može zajamčiti oporavak
nakon svakog kvara, zlonamjernog softvera ili gubitka uređaja.

Čuvajte zasebnu šifriranu sigurnosnu kopiju i svoju glavnu lozinku.
Prikazane snimke zaslona nastale su renderiranjem Flutter widgeta,
ne snimanjem fizičkih Android uređaja ili Windows radne površine.
Potpuna 1:1 pixel-perfect usporedba s referencama nije potvrđena.

Android predizdanje nema trajni Google Play produkcijski upload potpis,
a Windows instalacijski paketi nisu Authenticode potpisani.

© Brendigo
