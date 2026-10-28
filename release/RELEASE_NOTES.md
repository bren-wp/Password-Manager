# Veldigo v0.2.4 Preview 4 — sigurnost i stabilnost

**Pouzdanije spremanje. Provjera integriteta. Bolja privatnost.**

## Android i Windows pixel-parity nadogradnje

- Svih 26 aktualnih Flutter snimki sada se automatski snima u izvornim fizičkim rezolucijama referentnih Android i Windows PNG predložaka.
- CI blokira duplicirane snimke, prikaz pogrešnog zaslona i neodgovarajuće dimenzije slike.
- Android zaslon detalja otvara se na cijelom zaslonu; pri uređivanju se prikazuje aktualni zapis, nakon trajnog brisanja podaci se više ne prikazuju, a zaključavanje odmah zatvara detalje.
- Uvodni zaslon, dobrodošlica, položaj logotipa i njegov tirkizni sjaj dodatno su usklađeni s referentnim prikazima.
- Automatski testovi provjeravaju javne zaslone na razvojne poruke i demonstracijske vjerodajnice.
- `docs/PIXEL_PARITY_AUDIT.md` i `tools/visual_parity_audit.py` dokumentiraju postupak precizne usporedbe s referentnim slikama. **Vizualna 1:1 podudarnost svih piksela još nije potvrđena.**

## Najnovije ispravke

- Zatvaranje aplikacije tijekom otključavanja, uvoza ili spremanja sada prekida rad prethodne sesije i sprječava pozivanje zatvorenih Flutter slušatelja.
- Zahtjevi za otključavanje koji čekaju svoj red više ne mogu poništiti novije korisničko zaključavanje.
- Lokalne šifrirane rezervne kopije i provjere diskovnih transakcija ograničene su na 64 MiB, uz zaštitu od naknadnog rasta datoteke.
- Diskovni zapis provjerava se ključem iste transakcije, bez ovisnosti o promjenama stanja korisničkog sučelja.
- Dodani regresijski testovi za zatvaranje prozora, čekanje zahtjeva, zaključavanje pri spremanju i oporavak.

## Novosti

- Zaključavanje trezora sada poništava prethodnu sesiju: zakašnjela promjena glavne lozinke, spremanje, otključavanje ili uvoz više ne smiju vratiti tajne ključeve u RAM.
- Diskovne šifrirane kopije provjeravaju se ključem transakcije koji nije vezan uz naknadno zaključavanje sučelja, pa zaključavanje ne izaziva lažno oštećenje zapisa.
- Lokalni trezor i sve oporavne datoteke čitaju se ograničenim tokom podataka do 64 MiB radi zaštite memorije.
- Dodan je autentificirani oporavak iz izdvojene `.corrupt` kopije kad glavna datoteka nije dostupna.
- Windows aplikacija automatski zaključava trezor i pri gubitku fokusa, osim dok je aktivan namjenski vremenski ograničen odabir datoteke.
- Dodani regresijski testovi za utrke zaključavanja tijekom operacija i za prevelike/oštećene lokalne datoteke.


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
