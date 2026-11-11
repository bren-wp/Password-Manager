# Veldigo — Android ekran 01 korisničkog toka: Uvodni ekran / Splash

Datum: 11. studenoga 2026. Izvorni naziv u 15-referentnoj matrici: `14_Uvodni_ekran.png` (832 × 1856 fizičkih piksela). Redoslijed testiranja prema korisničkom toku započinje Splashom, iako matrica datoteka glavni trezor označava s 01.

## Polazno stanje

- `main` je sadržavao centrirani Veldigo štit, naziv, slogan, tamni radijalni gradijent i donji indikator fiksiran na 58 %.
- Prethodni arhivski RGB MAE iz `docs/PIXEL_PARITY_MEASURED_V030.md` za ovaj ekran: **7,97 / 255** (29. 10. 2026.). To nije mjerenje novog koda.
- Za provjeru su dostupne stvarne Flutter testne snimke, ne privatni izvorni Splash PNG. Stoga se nova apsolutna RGB 1:1 podudarnost ne može izmjeriti; nula odstupanja **nije dokazana**.

## Implementacija

1. Hero i podnožje razdvojeni su u nepreklapajuća područja `Column/Expanded`. Hero može vertikalno skrolati na niskim ekranima i pri povećanoj veličini fonta bez guranja indikatora učitavanja izvan zaslona.
2. Štit zadržava postojeći vlastiti vektorski `VeldigoLogo`, s ograničenim responsive dimenzijama 72–102 logička piksela. Wordmark se po potrebi može smanjiti da ne dođe do horizontalnog `RenderFlex` overflowa.
3. Pozadina, tipografija, sadržaj i boje ostali su vezani uz projektne `VColors` tokene. Nisu generirane ni dodane izmišljene reference ili brand grafike.
4. Živi `SplashScreen()` sada koristi **indeterminate** napredak umjesto lažne konstantne brojke 58 %. Screenshot fixture koristi `SplashScreen(progress: .58)` kako bi referentna testna snimka ostala ponovljiva.
5. Dodana je semantika logotipa i pokretanja aplikacije za čitače zaslona. Izgled ne imitira Android OS statusne/navigacijske trake.
6. Bez ikakvih promjena u `VaultStore`, AES-256-GCM, Argon2id, formatima trezora, uvozu/izvozu ili korisničkim tajnama.

## Automatske provjere

`test/android_splash_screen_pixel_parity_test.dart`:
- Layout na 280×480, 320×568, 320×640, 393×852, 416×928, 600×960;
- Dodatni test pri text scale 1.0 i 1.8;
- Indikator 58 % samo u determinističkoj galeriji;
- Indeterminate vrijednost u stvarnom pokretanju;
- Semantičke oznake i odsutnost Flutter overflow iznimaka.

## Sljedeći korak

Nakon zelenog CI-ja na točnom commitu te vizualnog pregleda novog PNG-a: Android **Dobrodošlica** (`15_Dobrodoslica.png`), zatim **Postavljanje glavne lozinke**, **Otključavanje**, **Glavni trezor** i ostali. Vizualna 1:1 potvrda zahtijeva privatni original, identičnu fizičku veličinu, font/locale/DPI i nula različitih RGB piksela u odgovarajućem app ROI području.
