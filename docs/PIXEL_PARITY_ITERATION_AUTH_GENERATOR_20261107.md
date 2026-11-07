# Veldigo — autentifikacija i generator, provjera ekran po ekran

Datum: 7. studenoga 2026. Grana: `fix/veldigo-auth-generator-parity-20261107`.

## Obuhvat i polazne brojke

| Platforma | Referentni ekran | Posljednji dokumentirani RGB MAE /255 | Status ove iteracije |
| --- | --- | ---: | --- |
| Windows | 02 Otključavanje | 34,73 | Ispravljen raspored u uskom desktop prozoru; ponoviti RGB usporedbu |
| Windows | 04 Generator | 33,57 | Ispravljeni raspon, dugotrajno povlačenje i layout; ponoviti RGB usporedbu |
| Android | 03 Otključavanje | 31,20 | Tipkovnica i raspored ostaju funkcionalni; ponoviti RGB usporedbu |
| Android | 02 Postavljanje glavne lozinke | 28,84 | Enter prelazi na potvrdu, ne šalje nepotpun obrazac; ponoviti RGB usporedbu |
| Android | 06 Generator | 27,55 | Dugi prikaz lozinke ostaje jednoredan, klizanje se ne nakuplja; ponoviti RGB usporedbu |

Brojke su **raniji bazni MAE**, preuzeti iz `PIXEL_PARITY_TRACKER_V034.md`, a ne rezultati nakon ove promjene. Nikakav zaslon nije ovom promjenom potvrđen kao RGB 1:1.

## Promjene

1. Windows aplikacija podržava minimalni prozor od 820×560. Ekran autentifikacije više ne prelazi u mobilnu Android varijantu ispod 850 px; desktop izgled ostaje aktivan i pri 820 px.
2. Generator na Windowsu zadržava desktop kontrole, uključujući potvrdne okvire, 8–64 znakova i maskiranu povijest i pri 820 px širine. Android generator zadržava prekidače i raspon 8–128.
3. Pomicanje klizača duljine sada samo ažurira prikaz ciljane duljine. **Nova kriptografski generirana lozinka nastaje jednom na otpuštanje**. Time se izbjegava prethodni niz privremenih tajni i istiskivanje povijesti jednim pomakom.
4. Procjena snage odnosi se na **trenutačno prikazanu**, već generiranu lozinku, ne na duljinu koja još nije primijenjena.
5. Na Androidu se i 128-znakovna lozinka prikazuje u jednom vodoravno pomičnom retku; širenje visine elementa neće potiskivati ostale kontrole.
6. U obrascu za stvaranje trezora prva tipka „Dalje” vodi na potvrdu glavne lozinke. Predaja obrasca ostaje vezana na završno polje i gumb. Otključavanje je i dalje moguće tipkom „Gotovo”.

## Automatske provjere

`test/auth_generator_screen_parity_regression_test.dart` provjerava:

- Windows prijavu i postavljanje na 820×560, 1200×800, 1586×992;
- Android tipkovnički redoslijed u obrascu za novu glavnu lozinku;
- jednu stavku maskirane povijesti nakon brojnih promjena položaja klizača;
- jednoredni prikaz duljih generiranih tajni na 320×640;
- Windows generator, desktop kontrole i raspon duljine na 820×560.

Postojeći CI i foto-galerija trebaju ponovno pokrenuti testove nakon commita. **Prolaz widget-testova nije dokaz pixel-perfect rezultata.**

## Uvjeti za stvarnu 1:1 potvrdu

Za svaki od 26 ekrana snimiti stvarni build istoga commita, istim DPI-jem, dimenzijom, fontom, lokalizacijom i testnim podacima kao izvornu privatnu referencu. Usporediti zasebne ROI regije aplikacije (ne Windows pozadinu ni OS trake), izmjeriti RGB MAE, udio RGB-identičnih piksela, rubove, tipografiju i interaktivnost. Izvornici nisu javno dostupni u repozitoriju; dok nisu dostupni, **apsolutno nulto odstupanje nije dokazivo**. Ne objavljivati korisničke privatne reference ili vjerodajnice u javnim artefaktima.

Nisu mijenjani AES-256-GCM, Argon2id, format trezora, datoteke sigurnosnih kopija ni korisnički podaci.


## Dvije izvorne reference — nova provjera baznog stanja

Dostupne su privatne originalne slike vlasnika (nisu objavljene u repozitoriju) i stvarne Flutter testne PNG snimke iz Actions runa **42408804157**. Mjerenje je provedeno u izvornim dimenzijama, bez rastezanja, Python Pillow/NumPy metodom.

| Ekran | Dimenzija | RGB MAE/255 cijele slike | RGB-identični pikseli | Dodatni ROI |
| --- | --- | ---: | ---: | --- |
| Android 03 Otključavanje | 887×1774 | **31,54** | 0,00 % | Obrazac (x40–845, y700–1420): 55,52 |
| Windows 04 Generator | 1586×992 | **33,59** | 0,0003 % | Središnji pravokutnik (x70–1518, y80–940): 27,54 |

**Važne granice:** ove vrijednosti su iz prethodne snimke i ne uključuju kasnije promjene redoslijeda kontrola, numeričkog polja duljine, podataka demonstracijskog generatora niti maskiranog unosa na prijavi. Windows original sadržava OS pozadinu i rubove prozora, pa čak ni središnji ROI još ne izolira točan app viewport. Android original sadržava sustavne trake koje se ne crtaju u Flutter testnoj snimci. Nulti RGB MAE nije postignut.

### Dodatne dorade nakon navedene snimke

- Windows 04: oznaka snage sada je uz segmentiranu traku, a numerička duljina u posebnom polju desno od klizača.
- Flutter screenshot fixture generira tri maskirana demo zapisa u Windows povijesti, te ispunjava Android prijavu **samo demonstracijskim** (maskiranim) unosom. Niti jedan stvaran korisnički pristupni podatak nije izložen.
- Android 03: istinita radnja oporavka iz lokalne šifrirane kopije pojavljuje se kao sekundarna kartica iznad primarnog CTA-a, bliže rasporedu izvornog predloška. Ne prikazuje se lažni gumb za biometrijsko otključavanje dok nema provjerene hardverske integracije.
- Nadodani widget-testovi ciljaju jednoredni prikaz 128 znakova, sekvencu tipkovnice i mobilni redoslijed kontrola.

Za sljedeću poštenu usporedbu treba preuzeti najnoviji screenshot artefakt baš s commita nakon ovih izmjena i ponovno izračunati **isti** ROI. Ne koristiti ovu staru brojku za tvrdnju da je novija verzija bolja ili lošija bez nove analize.
