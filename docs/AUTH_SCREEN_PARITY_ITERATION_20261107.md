# Veldigo — otključavanje i postavljanje glavne lozinke (iteracija)

**Datum:** 7. studenoga 2026. **Grana:** `fix/veldigo-auth-visibility-onboarding-parity-20261107`.

## Ekrani u ovom prolazu

| Platforma | Referenca | Izmjerena stara baza RGB MAE/255 | Obrađene kontrole |
| --- | --- | ---: | --- |
| Android | 02 Postavljanje glavne lozinke (887×1774) | 28,84 | Zaglavlje, stvarni povratak, dva nezavisno maskirana polja, pravila lozinke, CTA, pozadina |
| Android | 03 Otključavanje (887×1774) | 31,20 | Maskirani unos, lokalni oporavak, CTA, pozadina |
| Windows | 02 Otključavanje (1586×992) | 34,73 | Zadržan desktop raspored, zasebna provjera inputa, bez lažne biometrije |
| Windows | 11 Prvo postavljanje (1536×1024) | 20,05 | Dva odvojeno maskirana polja i postojeći desktop raspored |

**Važno:** to su prethodne polazne vrijednosti, a ne nove RGB mjere. Bez svježih renderiranih snimki točnog commita i originalnih referenci **niti jedan ekran nije dokazan kao pixel-perfect 1:1**.

## Implementirane promjene

1. Ikona povratka na mobilnom zaslonu stvaranja trezora stvarno vraća korisnika na ekran dobrodošlice. Dok je proces stvaranja/uvoza zauzet, povratak je onemogućen. U screenshot prikazu bez navigacijskog roditelja ne prikazuje se neaktivna navigacijska kontrola.
2. Glavna lozinka i polje potvrde imaju odvojene prekidače vidljivosti. Otkrivanje glavne lozinke više ne otkriva automatski njezinu potvrdu (i obrnuto).
3. Na Androidu tamni tirkizni gradijent pokriva cijelo područje Flutter prikaza, bez crtanja lažnih sistemskih traka. Unosna polja imaju veći vertikalni prostor za dodir.
4. Smjernice za glavnu lozinku organizirane su u jednu vizualnu karticu s četiri provjere. Nikakva postojeća funkcija spremanja nije uklonjena.
5. **Granica od najmanje 12 znakova ostaje obvezna.** Izvorna dizajnerska referenca navodi 8 znakova, ali zbog sigurnosti trezora ta vrijednost **namjerno nije kopirana**. Nema snižavanja sigurnosnih pravila radi vizualne paritetnosti.
6. Ne prikazuje se lažni biometrijski ili Windows Hello gumb dok ne postoji potpuna, provjerena i sigurna implementacija.

## Regresijska pokrivenost

Novi `test/auth_master_password_isolation_parity_test.dart` provjerava zasebnu vidljivost, privatne postavke softverske tipkovnice, funkcionalan povratak, odbijanje prekratke i nepodudarne glavne lozinke, dostupnost gumba i odsutnost overflow pogrešaka na **320×640, 393×852 i 480×900**. Postojeći Windows testovi obuhvaćaju i **820×560, 1200×800 i 1586×992**.

## Za prihvat ekrana

- Generirati stvarne snimke točno istog commita; uspoređivati s izvornim PNG-ovima u njihovim fizičkim dimenzijama, uz odvojene ROI za OS i aplikaciju.
- Mjeriti RGB MAE, identične piksele, tipografiju, obrise, koordinatni raspored, margine, sjene i krajnja stanja kontrola.
- Testirati Android tipkovnicu, orijentaciju, softversku navigaciju i različite text-scale faktore te Windows prikaz na 100/125/150 % DPI-ja.
- Nijedan proces prilagodbe ne smije mijenjati AES-256-GCM, Argon2id, pohranjene tajne ili format sigurnosnih kopija.

**Status:** kod i testovi su dodani, a certificiranje vizualne identičnosti i fizički testovi ostaju otvoreni do dokazivih rezultata.
