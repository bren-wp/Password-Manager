# Veldigo — Android ekran 01 korisničkog toka: Uvodni ekran / Splash

Datum: 11. studenoga 2026. Izvorni naziv u 15-referentnoj matrici: `14_Uvodni_ekran.png` (832 × 1856 fizičkih piksela). Redoslijed testiranja prema korisničkom toku započinje Splashom, iako matrica datoteka glavni trezor označava s 01.

## Polazno stanje

- `main` je sadržavao centrirani Veldigo štit, naziv, slogan, tamni radijalni gradijent i donji indikator fiksiran na 58 %.
- Prethodni arhivski RGB MAE iz `docs/PIXEL_PARITY_MEASURED_V030.md` za ovaj ekran: **7,97 / 255** (29. 10. 2026.). To nije mjerenje novog koda.
- Izvorni PNG pronađen je u korisnikovoj privatnoj biblioteci u arhivi `Veldigo_Android_Ekrani(2).zip`. Izvornik je ostao privatan, a stvarni Flutter screenshotovi uspoređeni su u istoj fizičkoj rezoluciji. Za međustanje nakon gradijenta MAE se smanjio s **7,9959/255** na **4,6300/255**, a udio identičnih RGB piksela narastao s **2,36 %** na **32,74 %**. Posljednja dorada flat štita još čeka novu PNG usporedbu; nula odstupanja **nije dokazana**.

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

Ekran **Dobrodošlica** (`15_Dobrodoslica.png`) sada je također obrađen u istom PR-u #23, s posebnim dokumentom `ANDROID_SCREEN_BY_SCREEN_WELCOME_20261111.md`. Sljedeći ekran nakon provjere obje snimke jest **Postavljanje glavne lozinke**, zatim **Otključavanje**, **Glavni trezor** i ostali. Vizualna 1:1 potvrda zahtijeva privatni original, identičnu fizičku veličinu, font/locale/DPI i nula različitih RGB piksela u odgovarajućem app ROI području.
