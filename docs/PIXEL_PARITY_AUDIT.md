# Veldigo — pixel-by-pixel UI parity audit

**Scope:** 15 Android and 11 Windows reference PNG files that accompany the original Veldigo UI design. This report is separate from the security and dead-code audits.

## Confirmed findings

1. **Duplicate Android screen captures (fixed).** The previously committed `01_Glavni_trezor.png` and `05_Detalji_lozinke.png` had the same Git blob SHA `4249b92a75602eba57f544e20143e6b2c3bdf526`; the account-detail screenshot was therefore not a distinct screen. The screenshot test now asserts that the details dialog opens, and `tools/publish_real_screenshots.py` rejects duplicate capture hashes. A successful recapture produced a separate details blob `d029cabf4778bf1148a2483b76fbf976fcdd2ee6`.
2. **Different capture dimensions (corrected and CI-verified).** Previous Flutter golden tests used generic 393 × 852 Android and 1200 × 800 Windows render targets; the supplied reference PNGs have multiple, larger native sizes. The capture specification now follows individual source dimensions, with Android DPR 2 and Windows DPR 1. This eliminates *dimension mismatch* for fresh reference-sized captures but **does not establish visual pixel parity**.
3. **Android account details now use a full-screen record page**, with live refresh after edits and hiding of permanently deleted credentials. The splash, onboarding emblem, hero spacing and shield highlight were adjusted toward the provided reference proportions. These improvements still require a visual-difference run.

4. **Visual appearance still requires exact comparison.** Current Flutter UI uses a Material 3 layout and custom shield painter. Reference mockups include different typography, gradients, icon compositions, navigation and desktop window chrome. The original Windows screenshots depict an operating-system desktop background that an isolated Flutter widget cannot capture. Do not state that the Flutter widget gallery is 1:1 with full Windows desktop screenshots.

## Physical pixel dimensions from the original reference archives

| Platform | Screens | Reference pixel sizes |
|---|---|---|
| Android | 01 | 843 × 1866 |
| Android | 02, 03, 06, 08 | 887 × 1774 |
| Android | 04 | 864 × 1821 |
| Android | 05 | 862 × 1824 |
| Android | 07 | 841 × 1870 |
| Android | 09 | 862 × 1825 |
| Android | 10 | 863 × 1823 |
| Android | 11–15 | 832 × 1856 |
| Windows | 01–04 | 1586 × 992 |
| Windows | 05–11 | 1536 × 1024 |

## Reproducible comparison

Keep the original reference ZIP files **outside** the public repository. They may contain licensed artwork, so do not automatically commit them.

Run Flutter capture and regenerate the gallery:

```bash
flutter pub get
flutter test --update-goldens tool/marketing_screenshots_test.dart
python tools/publish_real_screenshots.py
```

Compare against the supplied reference ZIPs after installing `Pillow`:

```bash
python -m pip install Pillow
python tools/visual_parity_audit.py \
  --android-zip "Veldigo_Android_Ekrani(2).zip" \
  --windows-zip "Veldigo_Windows_Ekrani(2).zip" \
  --actual assets/screenshots \
  --report build/veldigo-pixel-parity.md \
  --json build/veldigo-pixel-parity.json
```

The script reports original and capture dimensions, mean absolute RGB pixel error, structural edge error and exact 1:1 match per screen. For different dimensions it rescales only for *diagnostic* comparison, never marking a resized capture pixel-perfect. Duplicate captures are rejected.

## Acceptance criteria

Every screen must show the **correct functional state**, no duplicate or missing shots, native resolution matching references, no clipping/overlap at the target size and tested Android/Windows navigation. Exact 1:1 can only be reported for an image when dimensions match and pixel error is zero. Independent testing must separately verify gesture interactions, platform fonts, accessibility, scrolling and soft keyboards.

**Status:** Screenshot workflow passed on the current PR with **26 distinct files**, verified exact reference PNG physical dimensions and correct Android create/unlock/details navigation. The visual pixel-difference report against the original artwork is still pending; matching screenshot size and a non-duplicated capture are not proof of visual 1:1 parity.

## v0.2.6 strict-measurement update — 29 October 2026

- The visual audit no longer uses rounded mean RGB error to assert equality. A single channel differing by one unit is now counted, even when the rounded RGB MAE is `0.000`. Exact parity requires identical physical dimensions **and zero changed pixels**.
- Per-screen diagnostics now include RGB MAE, edge MAE, changed-pixel count and percentage, bounding rectangle of differences, maximum channel deviation, and a ranked list of the closest captures.
- `tools/test_visual_parity_audit.py` covers single-channel differences, same-color images of different dimensions, and ambiguous duplicate reference filenames. This Python suite is wired into the PR's quality workflow.
- The reference ZIP archives are **not checked into this repository and were not available in the current session**; therefore no per-screen RGB comparison against the original artworks has been executed here. All 26 existing Flutter screenshots remain useful rendering baselines, **not a completed pixel-perfect certification**.
- The Android UI now collapses nonessential vault chrome while the soft keyboard is visible and hides vault statistics at small available heights. Such responsive changes preserve the reference-sized layout, but should still be visually compared after capture.


## Windows generator follow-up — 29 October 2026

The supplied Windows reference `04_Generator_lozinki.png` has a compact
desktop generator, character-group checkboxes, a strength indicator inside
the generated-password panel, and a history section with masked passwords,
copy actions, and a clear action. The pre-existing shared Flutter widget
rendered essentially the mobile stack and had no history.

The Windows-width layout now has dedicated responsive panels and working
session-only password history. Old passwords remain masked in the history;
copy and clear are explicit actions. Android retains its existing layout
and switches. The history is intentionally in memory only and is **not**
persisted across widget teardown, vault lock, or application restart.

**This is a targeted UI change, not a claim of RGB-perfect parity.** New
Flutter captures, all 26 image comparisons, manual DPI/scroll/focus checks,
and native Windows QA still have to pass before visual signoff.
