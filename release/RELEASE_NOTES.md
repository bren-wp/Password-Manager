# Veldigo v0.2.2 — Preview 1

**Privatnije. Sigurnije spremanje. Bolji Android i Windows doživljaj.**

## Poboljšanja

- Prikaz svih 26 zaslona iz stvarnog renderiranog Flutter korisničkog
  sučelja u GitHub README-u — 15 Android i 11 Windows rasporeda
- Obrasci za račune sada ostaju otvoreni dok upis u šifrirani trezor
  stvarno ne uspije; pri pogrešci uneseni podaci ostaju dostupni za ponovni pokušaj
- Lokalna šifrirana kopija prije uvoza i promjene glavne lozinke
  provjerava se nakon zapisivanja na disk
- Zaštita protiv istodobnog stvaranja istog trezora u dvije instance
- Oporavak kopija uz zaključavanje datoteke i otkrivanje konkurentnih promjena
- Brzo ručno zaključavanje Android i Windows trezora
- Dodatna Android ograničenja izvoza aplikacijskih podataka u
  automatske cloud i device-transfer sigurnosne kopije
- Dodani regresijski testovi za spremanje pri grešci, očuvanje kopija,
  istodobno kreiranje i oporavak

## Datoteke

- `Veldigo-Android.apk` — instalacija na Android
- `Veldigo-Android.aab` — Android App Bundle predizdanje
- `Veldigo-portable.exe` — prijenosna Windows verzija
- `Veldigo-Setup.exe` — Windows instalacijski program
- `Veldigo-Windows-portable.zip` — Windows direktorij
- `Android-SHA256.txt` i `Windows-SHA256.txt` — provjera integriteta preuzimanja

## Važno

Ovo je **predizdanje**. Snimke potječu iz automatskog Flutter UI renderiranja,
a ne s fizičkih uređaja. Potpuna 1:1 pixel-perfect usklađenost i neovisna
revizija sigurnosti još nisu potvrđene.

Android predizdanje nije potpisano privatnim Google Play upload ključem,
a Windows paketi nisu Authenticode potpisani. Nemojte ih koristiti kao
produkcijski trezor za nezamjenjive zapise.

Zasebno čuvajte šifriranu kopiju trezora i glavnu lozinku. Nema
daljinskog resetiranja lozinke, a zaštita od svih vrsta kvara hardvera
ili gubitka uređaja ne može biti zajamčena.

© Brendigo
