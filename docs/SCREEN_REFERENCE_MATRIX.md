# Veldigo Android + Windows — source screen matrix

The UI reference set provided by the project owner has 15 Android PNG images
and 11 Windows PNG images. All are designs, **not application screenshots**.
The app must match them as closely as possible at their intended densities
while preserving usability on other screen sizes.

These source PNGs are intentionally not stored as application graphics:
passwords, emails and dates appearing in mockups are fabricated demonstration
data and must never be used as real credentials in a production application.

## Android (15 reference screens)

| Screen | Reference PNG name | Original pixels | Required UI |
|---|---|---|---|
| 01 | 01_Glavni_trezor.png | 843×1866 | Branded header, protection status, search, 3 counters, password list, floating add, bottom navigation |
| 02 | 02_Postavljanje_glavne_lozinke.png | 887×1774 | Master password/confirmation, validity, security disclaimer, create vault |
| 03 | 03_Otkljucavanje.png | 887×1774 | Centered Veldigo shield, masked master password, unlock |
| 04 | 04_Dodavanje_lozinke.png | 864×1821 | Service icon, website, username, hidden secret, strength, category, note, favorite, save |
| 05 | 05_Detalji_lozinke.png | 862×1824 | Service card, masked credentials, copy and edit, deletion with confirmation |
| 06 | 06_Generator_lozinki.png | 887×1774 | Length slider, character groups, strength, regenerate/copy |
| 07 | 07_Sigurnosni_centar.png | 841×1870 | Local security score, weak/repeated counts, recommendations |
| 08 | 08_Sigurne_biljeske.png | 887×1774 | Note search, categories, note list and create |
| 09 | 09_Autentifikator_TOTP.png | 862×1825 | Local six-digit TOTP, progress, add credentials |
| 10 | 10_Postavke.png | 863×1823 | Security, backup, appearance, language |
| 11 | 11_Kategorije.png | 832×1856 | Category search/list, counts, add |
| 12 | 12_Sigurnosna_kopija.png | 832×1856 | Encrypted backup export/restore |
| 13 | 13_Kartice.png | 832×1856 | Masked payment cards, add/edit |
| 14 | 14_Uvodni_ekran.png | 832×1856 | Splash logo, dark gradient |
| 15 | 15_Dobrodoslica.png | 832×1856 | Teal shield, benefits, primary start CTA |

## Windows (11 reference screens)

| Screen | Reference PNG name | Original pixels | Required UI |
|---|---|---|---|
| 01 | 01_Glavni_trezor.png | 1586×992 | Non-maximized window with left navigation, search, stats, table and details |
| 02 | 02_Otkljucavanje.png | 1586×992 | Centered compact unlock window |
| 03 | 03_Dodavanje_lozinke.png | 1586×992 | Centered edit dialog over main app |
| 04 | 04_Generator_lozinki.png | 1586×992 | Wide generator layout and history |
| 05 | 05_Sigurnosni_centar.png | 1536×1024 | Security cards and actionable recommendations |
| 06 | 06_Sigurne_biljeske.png | 1536×1024 | Sidebar and split notes list/editor |
| 07 | 07_Postavke.png | 1536×1024 | Two-column settings groups |
| 08 | 08_Sigurnosna_kopija.png | 1536×1024 | Export/restore panels |
| 09 | 09_Autentifikator.png | 1536×1024 | TOTP cards with real countdown |
| 10 | 10_Kategorije.png | 1536×1024 | Category cards with counters/actions |
| 11 | 11_Prvo_postavljanje.png | 1536×1024 | Compact centered create-vault screen |

## Validation criteria

- Screenshot matching must use captured frames of *running binaries* at a
  precisely specified logical size, pixel ratio, text scale and locale.
- Reference images have different aspect ratios and include OS/wallpaper
  pixels; compare the matching app viewport, not unrelated desktop background.
- Verify 320dp/360dp/393dp/600dp and Windows 820×560/1200×800/1600×900.
- Record overflow errors, button tap sizes, keyboard interactions, input
  visibility when typing, clipped text, OS high-contrast and 1.5× text.
- Reference cards contain mock values. Live counters depend on actual data.
- A build passing Flutter analysis does **not** establish pixel-perfect parity.
- Design or icons cannot be said to match 1:1 before visual diffs are checked.

