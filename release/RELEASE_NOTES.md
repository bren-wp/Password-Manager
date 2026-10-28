# Veldigo v0.2.4 — sigurnosno predizdanje

**Pouzdanije spremanje. Provjera integriteta. Bolja privatnost.**

## Novosti

- Ojačano spremanje prethodnih šifriranih verzija trezora i oporavak nakon prekida zapisivanja.
- Izmijenjeni Windows portable sadržaj provjerava se kroz ugrađeni SHA-256 manifest prije izvršavanja; nepotpune ili izmijenjene datoteke ponovno se raspakiravaju.
- Uvoz šifriranih kopija sada se odvija kroz ograničen tok podataka, bez učitavanja proizvoljno velikih datoteka u memoriju.
- `file_picker` migriran je s ranjive verzije 10.3.10 na novu generaciju 13.3.0. Prethodna verzija obuhvaćena je upozorenjem CVE-2026-38093; ono ne navodi formalno potvrđenu zakrpanu verziju. Neovisna provjera Android implementacije ostaje uvjet produkcijskog izdavanja.
- Autentifikator je dobio provjeru TOTP kodova prema RFC 6238 i strože tumačenje Base32 tajnih ključeva.
- Prikaz otkrivenih lozinki i CVV-a automatski se skriva pri promjeni računa.
- Uklonjene su razvojne poruke i neaktivne postavke, zastarjeli prikazi, generirani lokalni artefakti i neiskorišteni workflow.
- README zadržava svih 26 stvarno renderiranih Flutter zaslona (15 Android i 11 Windows rasporeda).

## Dostupne datoteke

- `Veldigo-Android.apk`
- `Veldigo-Android.aab`
- `Veldigo-portable.exe`
- `Veldigo-Setup.exe`
- `Veldigo-Windows-portable.zip`
- `Android-SHA256.txt` i `Windows-SHA256.txt`

## Sigurnost

Ovo je **predizdanje**, a ne neovisno certificiran upravitelj lozinki.
Nemojte ga smatrati produkcijski sigurnim samo na temelju prolaska
automatskih testova. Android paket još zahtijeva produkcijski upload ključ,
a Windows izvršne datoteke Authenticode potpis.

Čuvajte više neovisnih šifriranih sigurnosnih kopija i glavnu lozinku.
Testiranje na fizičkim uređajima, potpuna 1:1 vizualna usporedba i neovisni
penetracijski audit nisu završeni.

© Brendigo
