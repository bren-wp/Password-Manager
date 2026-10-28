# Veldigo — Password Manager

**Veldigo** is a privacy-first password vault for **Android and Windows**, built
with a single responsive Flutter codebase. Dark navy surfaces, Veldigo turquoise
accents, clean forms and adaptive layouts are inspired by the project's original
Veldigo design specification.

> **Development preview — not production ready.** Security audit and pixel-perfect
> screen-by-screen visual verification are still required before storing important
> passwords or distributing a release.

## What works in the current code

- Create a device-local encrypted vault with a master password (minimum 12 characters).
- Unlock, lock, add, edit, delete, search, categorize and favorite password records.
- Store secure notes, card entries and TOTP authentication secrets.
- Generate random passwords from selectable character groups.
- Calculate standard six-digit TOTP codes from manually entered Base32 seeds.
- Review basic local password hygiene: short/simple and repeated passwords.
- Export and import encrypted `.veldigo` backup files for Android–Windows transfers.
- Copy credentials to clipboard with best-effort clearing after 30 seconds.
- Adaptive layouts with a mobile bottom bar / drawer and desktop sidebar.
- Windows starts in a resizable 1200 × 800 window with a minimum of 820 × 560,
  **not** maximized.

## Build

Prerequisite: Flutter stable SDK, Android SDK for Android, Visual Studio C++
Desktop development tools for Windows.

On **Windows PowerShell**:

```powershell
.\scripts\bootstrap.ps1
flutter analyze
flutter test
flutter run -d windows
flutter build windows --release
flutter build apk --release
```

On **macOS/Linux** (Android development):

```bash
bash scripts/bootstrap.sh
flutter analyze
flutter test
flutter run -d android
flutter build apk --debug
```

The first bootstrap generates standard Flutter Android/Windows platform projects.
Platform scaffolds should be checked into the repository after regeneration and
platform-specific Android policies, signing, icon and application labels are set.

### Repository layout

- `lib/core`: record model, password generator, encrypted vault format and storage
- `lib/ui`: Veldigo dark theme and adaptive Android/Windows screens
- `test`: preliminary unit/widget tests
- `.github/workflows`: Linux Android and Windows build checks
- `SECURITY.md`: security design, risks and outstanding work

## Security design

Argon2id derives the 256-bit encryption key from the user's master password and
a random 128-bit salt; AES-256-GCM encrypts/authenticates records at rest.
No service account, network sync or backend is required for local storage.
Encrypted backups use the same master password as the source vault.

**Warning:** This is a first-pass implementation, *not* an audited credential
product. Do not use real passwords before independent review and hardening.

## Design / product plan

The reference design supplies **15 Android** and **11 Windows** screens. The
responsive Veldigo navigation and key feature groups have been implemented,
but exact 1:1 per-screen rendering has not yet been validated against reference
PNG sizes, fonts, paddings and breakpoints.

Next milestones: compare all 26 reference screenshots against rendered widgets,
integrate branded app icon/splash; Android native autofill and screen-capture
protection; Windows Hello; biometric unlock; password import from existing
managers; QR camera TOTP enrollment; automated backup tests; signing,
reproducible Android AAB/APK and Windows installer release process.

## Brand and license

**Product:** Veldigo · **Author:** Brendigo

MIT License. © 2026 Brendigo.
