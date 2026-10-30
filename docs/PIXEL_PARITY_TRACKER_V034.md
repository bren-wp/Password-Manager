# Veldigo Android + Windows — matrica pixel-parity provjere

## Što znači 1:1

- **Pixel-perfect nije subjektivna oznaka.** Potrebne su identične fizičke dimenzije, identičan RGB rezultat u sadržaju aplikacije, funkcionalni gumbi te provjeren raspored na uređajima i DPI postavkama. Android status/navigacijske trake i Windows radna površina/prikaz prozora su OS sadržaj; ti se dijelovi analiziraju zasebno.
- Referentne izvorne PNG slike korisnika **nisu u javnom GitHub repozitoriju** i ne smiju se objaviti. Alat `tools/visual_parity_audit.py` lokalno uspoređuje stvarne snimke i originalne ZIP-ove.
- Sljedeće vrijednosti su **stara mjerena polazna točka** iz stvarnih Flutter snimki **v0.3.1**; nisu izmjerene nakon promjena ovog PR-a. Vrijednost je RGB MAE u rasponu 0–255, manje je bolje. Sve 26 snimki imaju odgovarajuće dimenzije, **0/26 su bili točno RGB-identični**.
- Oznaka "Dorađeno" označava da je kod promijenjen, **ne** da je rezultat 1:1. Nakon svakog UI commita potreban je novi rezultat na stvarnim Flutter snimkama i pregled funkcionalnosti.

## Android (15/15)

| Zaslon | V0.3.1 RGB MAE | Status u iteraciji v0.3.4 |
|---|---:|---|
| 01 Glavni trezor | 18.57 | Sljedeći |
| 02 Postavljanje glavne lozinke | 28.84 | Dorađeno – provjera u CI |
| 03 Otkljucavanje | 31.20 | Dorađeno – provjera u CI |
| 04 Dodavanje lozinke | 23.70 | Sljedeći |
| 05 Detalji lozinke | 25.08 | Sljedeći |
| 06 Generator lozinki | 27.55 | Prethodna dorada + novi logo |
| 07 Sigurnosni centar | 25.68 | Sljedeći |
| 08 Sigurne biljeske | 23.98 | Sljedeći |
| 09 Autentifikator TOTP | 24.07 | Sljedeći |
| 10 Postavke | 17.66 | Sljedeći |
| 11 Kategorije | 13.01 | Sljedeći |
| 12 Sigurnosna kopija | 23.50 | Sljedeći |
| 13 Kartice | 26.38 | Sljedeći |
| 14 Uvodni ekran | 7.97 | Sljedeći |
| 15 Dobrodoslica | 16.79 | Sljedeći |

## Windows (11/11)

| Zaslon | V0.3.1 RGB MAE | Status u iteraciji v0.3.4 |
|---|---:|---|
| 01 Glavni trezor | 22.30 | Sljedeći |
| 02 Otkljucavanje | 34.73 | Dorađeno – provjera u CI |
| 03 Dodavanje lozinke | 14.97 | Sljedeći |
| 04 Generator lozinki | 33.57 | Dorađeno – raspon 8–64 |
| 05 Sigurnosni centar | 15.63 | Sljedeći |
| 06 Sigurne biljeske | 14.43 | Sljedeći |
| 07 Postavke | 13.64 | Sljedeći |
| 08 Sigurnosna kopija | 20.63 | Sljedeći |
| 09 Autentifikator | 18.50 | Sljedeći |
| 10 Kategorije | 18.88 | Sljedeći |
| 11 Prvo postavljanje | 20.05 | Isti auth widget – za mjerenje |

## Aktualna iteracija

1. **Android postavljanje trezora, Android prijava, Windows otključavanje i prvo postavljanje:** revidirani razmaci, tipografija, logo, informacije o sigurnosti i layout. Funkcionalna pomoć za zaboravljenu lozinku jasno objašnjava ograničenja i ne nudi lažni reset.
2. **Windows generator:** slider 8–64, Android generator ostaje 8–128. Osnovni generator lozinki i AES-256-GCM/Argon2id strukture nisu promijenjeni.
3. **Zajednički logo:** za Android i Windows uveden je vektorski štit s punim V i sjenčanjem, bez vanjske slike i bez mrežne ovisnosti.
4. **Regresije:** Android 320×640, 393×852 i 480×900; Windows 1200×800. Provjeravaju se gumbi, semantika i Flutter iznimke.

## Kriteriji za stvarnu prihvaćenost svakog zaslona

1. Izraditi **novu** stvarnu Flutter snimku iz točno istog Git commita kao UI promjena (bez zastarjelih PNG-ova).
2. Lokalno usporediti PNG reference i snimku **bez rastezanja**, isključiti samo sistemsku traku/podlogu iz ocjene samog sučelja te navesti ROI koordinate.
3. Provjeriti font, boje, margine, dimenzije, logo, ikonice, gradijente, boje obruba, redoslijed elemenata i tekst.
4. Testirati fizički Android s različitim gustoćama i Windows s 100%, 125% i 150% DPI.
5. Potvrditi stvarni rad svake kontrole, navigacije, stanja praznog trezora, pristupačnosti i oporavka pogrešaka.
6. **Ne prikazivati neimplementirane biometrijske/Windows Hello radnje** samo radi podudaranja s referentnom slikom. Sigurnost je preduvjet funkcionalnosti.

## Trenutna ograničenja

Ne postoji valjano dokazano stanje "svih 26 1:1". Tridesetak piksela ukupne pogreške mogu dominirati OS pozadina i različiti primjerci podataka, a stvarne boje/razmaci moraju se zasebno mjeriti po regijama. Ovaj tracker omogućuje obraditi svaki zaslon bez skrivanja nepreostalih razlika.
