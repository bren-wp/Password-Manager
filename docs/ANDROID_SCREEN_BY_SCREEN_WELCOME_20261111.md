# Android UI parity — korak 2: Dobrodošlica

Datum: 11. studenoga 2026. Nastavak **istog otvorenog PR-a #23**.
Datoteka izvornog dizajna: `Veldigo_Android_Ekrani(2).zip/Android/15_Dobrodoslica.png`.
Izvorne reference su iz korisnikove privatne biblioteke; **ne objavljivati originalne PNG-ove ni arhive na GitHubu**.

## Polazno mjerenje prije ovog prolaza

Izvorni PNG i stvarni Flutter widget-capture iz ranijeg commita imaju **832×1856** fizičkih piksela i uspoređeni su bez skaliranja, pomoću Pillow/NumPy RGB razlike.

| Područje | RGB MAE / 255 | 100 % identični RGB pikseli |
| --- | ---: | ---: |
| Cijeli kadar | **16,9991** | **1,7816 %** |
| App kadar bez gornjih 100 px | 17,7782 | 1,2034 % |
| Štit i naslov (x40–792, y170–820) | 21,3934 | 0,0266 % |
| Kartica (x40–792, y900–1165) | 20,3979 | 0,5625 % |
| Donje radnje (x30–800, y1480–1815) | 34,8738 | 3,0866 % |

Ovo su stare vrijednosti, **ne** izmjerena poboljšanja nakon izmjena iz ovog dokumenta.

## Što je promijenjeno

1. Gradijent Android Dobrodošlice koristi iste tamnonavijske i tirkizne vrijednosti koje su prethodno izmjerene i primijenjene na uvodnom ekranu.
2. Veldigo štit sada koristi ravni (flat), geometrijski prikaz iz reference, s većom veličinom i vertikalnim pomakom. To je postojeći vektorski painter, ne nova vanjska slika.
3. Naslovi su pomaknuti na referentnu visinu; obje naslovne linije koriste usklađenu veličinu, a opis ima kraći razmak od naslova.
4. Kartica pogodnosti ima širinu i visinu bližu izvornom dizajnu te ostaje stvarna `VPanel` komponenta.
5. Prvi indikator je izduženi tirkizni oblik, druga dva su mala siva kružića.
6. Primarni gumb je na izvornijoj visini, a strelica je **desno** od naziva; drugim ekranima nije promijenjen redoslijed ikona.
7. Sekundarna radnja ima razlikovne sive/tirkizne tekstualne segmente, ali tekst **Uvezite kopiju** ostaje namjerno drugačiji od referentnog `Otključajte ga`. Kod prvog pokretanja lokalni trezor još ne postoji, stoga bi natpis `Otključajte ga` lažno tvrdio da se postojeći trezor može otključati umjesto uvesti. To je funkcionalno i sigurnosno svjesna iznimka od 1:1 teksta.
8. Ako import callback nije osiguran, sekundarna radnja više **ne** poziva `onStart` i ne prikriva kreiranje trezora kao uvoz.
9. Za kompaktnije zaslone raspored i dalje koristi skrolabilan sadržaj i zasebno postavljene donje radnje.

## Regresijski testovi

`test/android_welcome_source_geometry_test.dart` provjerava osnovne koordinate i redoslijed elemenata na logičkoj referentnoj veličini 416×928, fizički 832×1856 pri DPR=2, uključujući:
- Logo, lijevi/desni rub kartice, prvi indikator (22×7 dp), gumb i strelicu iza natpisa;
- Stvarno odvojene callbackove `onStart` i `onImport`;
- Funkcionalnu vidljivost na 320×640, 393×852, 480×900 i 600×960, sa skaliranjem teksta 1.0× i 1.5×.

## Preostali uvjeti

- Preuzeti screenshot-artifact točno s najnovijeg SHA-a **nakon svih UI promjena** i ponovno izračunati istu RGB/ROI matricu.
- Usporediti Android sistemske trake zasebno (testna Flutter snimka ne oponaša ih).
- Izmjeriti koordinatne i tipografske razlike, provjeriti kontrast i čitače zaslona na stvarnom uređaju.
- Nastaviti dalje na Android `02_Postavljanje_glavne_lozinke`, pa `03_Otkljucavanje`, bez izmjena šifriranja, pohrane i glavne lozinke.

**Status: UI izmjene i testna pokrivenost spremljene, vizualna 1:1/0 % identičnost nije potvrđena.**
