# Veldigo v0.3.0 preview — 26-screen measured visual parity

**Audit:** 29 October 2026. Original user-supplied Android (15) and Windows (11) reference ZIP files were compared against **actual Flutter widget-test PNG captures** from [GitHub Actions run 40964146138](https://github.com/bren-wp/Password-Manager/actions/runs/40964146138).

The original reference images remain private. All 26 captures had native dimensions matching their corresponding references; **0/26 were RGB-identical**. RGB MAE is the mean absolute channel difference on a 0–255 scale, with 0 as perfect. Metrics were measured with Pillow from original-size PNGs.

| Platform | Screen | RGB MAE / 255 | RGB-identical? |
|---|---|---:|:---:|
| Android | 01_Glavni_trezor | 18.57 | NO |
| Android | 02_Postavljanje_glavne_lozinke | 28.84 | NO |
| Android | 03_Otkljucavanje | 31.44 | NO |
| Android | 04_Dodavanje_lozinke | 23.70 | NO |
| Android | 05_Detalji_lozinke | 25.08 | NO |
| Android | 06_Generator_lozinki | 27.31 | NO |
| Android | 07_Sigurnosni_centar | 25.68 | NO |
| Android | 08_Sigurne_biljeske | 23.98 | NO |
| Android | 09_Autentifikator_TOTP | 24.15 | NO |
| Android | 10_Postavke | 17.66 | NO |
| Android | 11_Kategorije | 13.01 | NO |
| Android | 12_Sigurnosna_kopija | 23.50 | NO |
| Android | 13_Kartice | 26.38 | NO |
| Android | 14_Uvodni_ekran | 7.97 | NO |
| Android | 15_Dobrodoslica | 16.79 | NO |
| Windows | 01_Glavni_trezor | 22.30 | NO |
| Windows | 02_Otkljucavanje | 34.74 | NO |
| Windows | 03_Dodavanje_lozinke | 14.97 | NO |
| Windows | 04_Generator_lozinki | 33.58 | NO |
| Windows | 05_Sigurnosni_centar | 15.63 | NO |
| Windows | 06_Sigurne_biljeske | 14.43 | NO |
| Windows | 07_Postavke | 13.64 | NO |
| Windows | 08_Sigurnosna_kopija | 20.63 | NO |
| Windows | 09_Autentifikator | 18.56 | NO |
| Windows | 10_Kategorije | 18.89 | NO |
| Windows | 11_Prvo_postavljanje | 20.05 | NO |

**Average MAE:** Android **22.27**; Windows **20.68**. Highest measured visual differences: Android unlock, Android master-password setup, Android generator; Windows unlock and generator.

## Important measurement limits
- This comparison uses rendered Flutter test captures, not screenshots from physical Windows and Android devices. It is **not** certification of pixel-perfect 1:1 production UI.
- Some Windows reference images include host wallpaper/window chrome, which must be segmented before measuring the application viewport alone.
- Differences in example data, font rasterization, icon assets, DPI and OS status/navigation bars can dominate aggregate error.
- Future changes should compare each region, align viewport backgrounds and maintain both functional QA and visual diff reports. Do not publish the private reference ZIPs to GitHub.

## Next gates
Generate updated captures at the same native dimensions after UI changes; compute MAE, changed-pixel count, edge differences and viewport-segmented scores, then inspect all 26 screens manually and on physical Android/Windows devices before making any full parity claim.
