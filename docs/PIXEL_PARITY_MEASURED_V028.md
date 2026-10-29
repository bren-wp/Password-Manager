# Veldigo v0.2.8 — stvarni vizualni audit 26 zaslona

**Datum:** 29. listopada 2026. **Metoda:** originalni vlasnikovi ZIP-ovi s 15 Android i 11 Windows PNG datoteka uspoređeni s 26 stvarnih Flutter golden snimki s demonstracijskim podacima. **GitHub Actions capture:** run 40803704447, grana `feat/veldigo-v028-reference-pixel-parity`.

**Važno:** ove originalne arhive nisu stavljene u javni GitHub repozitorij. Snimke dolaze iz Flutter widget-test okruženja, ne iz stvarnih Android/Windows binarnih aplikacija. Ispravljen je problem da se umjesto Roboto slova/Material ikona prikazuju Ahem pravokutnici. Za Android se koristi jednoliko fizičko DPR skaliranje umjesto rastezanja `BoxFit.fill`.

## Rezultat mjerenja

- **26/26** parova ima jednake fizičke dimenzije.
- **0/26** parova je točno RGB 1:1. Niti jedan zaslon nije certificiran kao pixel-perfect.
- RGB MAE je srednja apsolutna razlika kanala na skali 0–255 (manje = bliže). Potpuna 1:1 usklađenost zahtijeva isti broj piksela i nula različitih RGB piksela.
- Windows reference 01–04 sadrže i pozadinu Windows operacijskog sustava, dok Flutter test snima površinu aplikacije. Usporedba cijelih slika zato ne izolira preciznost samog sučelja. Različit demonstracijski sadržaj dodatno povećava pogrešku.

| Platforma | Zaslon | Original/Flutter (px) | RGB MAE / 255 | Različiti pikseli | Točno 1:1 |
|---|---|---|---:|---:|---|
| Android | 01_Glavni_trezor | 843×1866 | 16.824 | 100.00% | NE |
| Android | 02_Postavljanje_glavne_lozinke | 887×1774 | 27.194 | 99.97% | NE |
| Android | 03_Otkljucavanje | 887×1774 | 29.831 | 100.00% | NE |
| Android | 04_Dodavanje_lozinke | 864×1821 | 23.204 | 99.87% | NE |
| Android | 05_Detalji_lozinke | 862×1824 | 25.407 | 99.97% | NE |
| Android | 06_Generator_lozinki | 887×1774 | 29.977 | 100.00% | NE |
| Android | 07_Sigurnosni_centar | 841×1870 | 25.586 | 99.97% | NE |
| Android | 08_Sigurne_biljeske | 887×1774 | 24.193 | 100.00% | NE |
| Android | 09_Autentifikator_TOTP | 862×1825 | 24.680 | 100.00% | NE |
| Android | 10_Postavke | 863×1823 | 18.406 | 100.00% | NE |
| Android | 11_Kategorije | 832×1856 | 12.653 | 72.63% | NE |
| Android | 12_Sigurnosna_kopija | 832×1856 | 16.775 | 72.19% | NE |
| Android | 13_Kartice | 832×1856 | 25.754 | 73.39% | NE |
| Android | 14_Uvodni_ekran | 832×1856 | 7.945 | 97.64% | NE |
| Android | 15_Dobrodoslica | 832×1856 | 20.344 | 98.36% | NE |
| Windows | 01_Glavni_trezor | 1586×992 | 22.005 | 99.99% | NE |
| Windows | 02_Otkljucavanje | 1586×992 | 34.473 | 100.00% | NE |
| Windows | 03_Dodavanje_lozinke | 1586×992 | 14.371 | 99.99% | NE |
| Windows | 04_Generator_lozinki | 1586×992 | 33.693 | 100.00% | NE |
| Windows | 05_Sigurnosni_centar | 1536×1024 | 15.752 | 100.00% | NE |
| Windows | 06_Sigurne_biljeske | 1536×1024 | 15.749 | 100.00% | NE |
| Windows | 07_Postavke | 1536×1024 | 13.114 | 100.00% | NE |
| Windows | 08_Sigurnosna_kopija | 1536×1024 | 21.071 | 100.00% | NE |
| Windows | 09_Autentifikator | 1536×1024 | 18.989 | 100.00% | NE |
| Windows | 10_Kategorije | 1536×1024 | 18.825 | 100.00% | NE |
| Windows | 11_Prvo_postavljanje | 1536×1024 | 19.943 | 100.00% | NE |

## Dokazani pomaci i otvorena odstupanja

- Android glavni trezor: RGB MAE **17,864 → 16,824** nakon ispravaka naslova, statističkih kartica i rasporeda.
- Android kategorije: **13,455 → 12,653**; sigurnosna kopija: **18,083 → 16,775** nakon zajedničkih stilskih promjena.
- Uključeni su novi izgled kartica s maskiranim brojem, funkcionalni gumbi te novi generator i TOTP postupci. Pojedinačni MAE može rasti kad se raspored približava referenci, ali se ne poklopi s položajem cijelog originalnog predloška; vizualna kvaliteta nije isto što i jedna agregirana brojka.
- Najveća otvorena odstupanja među Android ekranima: generator, otključavanje i postavljanje glavne lozinke; među Windows ekranima: otključavanje i generator.
- Preostaju detaljni 1:1 pregledi tipografije, raspona boja, ikona i koordinata, izolirana usporedba Windows app-viewporta, te testiranje na fizičkim uređajima.

## Ponovno mjerenje

Na računalu s lokalno dostupnim originalnim ZIP-ovima i stvarnim Flutter snimkama pokrenuti:

```bash
python tools/visual_parity_audit.py \
  --android-zip "Veldigo_Android_Ekrani(3).zip" \
  --windows-zip "Veldigo_Windows_Ekrani(3).zip" \
  --actual assets/screenshots \
  --report build/veldigo-pixel-parity.md \
  --json build/veldigo-pixel-parity.json
```

Izvorne privatne arhive ne uključivati u javna izdanja. Mjerenja ne zamjenjuju sigurnosni audit, uvid u stvarno prikazivanje fontova na OS-u, testove pristupačnosti ili testove oporavka trezora.
