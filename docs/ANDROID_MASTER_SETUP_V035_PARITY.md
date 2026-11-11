# Veldigo Android — master password setup pixel-parity pass (v0.3.5)

Source reference: private archive `Veldigo_Android_Ekrani(2).zip`, screen `02_Postavljanje_glavne_lozinke.png`, physical size **887×1774**. Original design image is not checked into the public repository.

## Measured starting point

Latest main Flutter screenshot checked at the identical 887×1774 physical image dimensions (no rescaling):

| ROI region | RGB MAE / 255 |
| --- | ---: |
| Whole image | **30.4455** |
| Header and logo (x40–845, y65–440) | **24.3504** |
| Master password inputs (x45–820, y630–950) | **15.7963** |
| Strength and criteria (x45–820, y970–1260) | **23.8454** |
| Lower part (x45–820, y1260–1740) | **65.1345** |

This is *pre-v0.3.5* baseline. It includes Android OS status/navigation bars and background, so full-frame RGB MAE is useful diagnostically but is not an isolated app-only ROI certification.

## Changes made

- Bigger branded shield and adjusted mobile title and subtitle rhythm, with the description capped to a readable width instead of stretching across the screen.
- Larger 2-stage masked credential input affordances. Prefix icons are removed on Android setup to better match the reference; Windows and Android unlock keep existing icons.
- Four stronger, thicker status segments aligned with the password strength label; criteria card enlarged and made easier to read.
- Original design text says a minimum of **eight** characters. We intentionally keep the **security-enforced 12-character minimum** in both store and form, so the design remains a guide rather than permission to reduce security.
- Replaced the oversized mobile import box by a compact secondary text action, while maintaining the actual encrypted import operation.
- The mobile primary CTA uses a right-hand arrow and remains accessible when scrolling or the soft keyboard opens.
- No changes to AES-256-GCM, Argon2id, private files, vault serialization, backup format, password submission or signing requirements.
- New widget-test cases check secure setup behavior, phone and zoom layouts, real import control and Windows layout isolation.

## Delivery plan

The PR includes version `0.3.5+18`, Inno Setup metadata, release notes and a **gated preview** workflow for Android APK + AAB, Windows binaries and SHA-256 files. Trigger only from the release branch `release/veldigo-v035-preview` after the development PR has passed its checks and been merged into main.

The preview artifact uses **debug signing by explicit CI opt-in**, not an actual Google Play upload key. Users needing Play Store updates must sign through their own configured, matching release/upload keystore.

## Acceptance status

- **Code and regression tests:** awaiting full CI run for the final PR SHA.
- **Visual:** screenshot comparison against the original PNG after the new Flutter capture, plus real Android physical-device validation, pending.
- **Exact RGB identity 1:1 / 0% deviation:** not proven, and not represented as complete.
