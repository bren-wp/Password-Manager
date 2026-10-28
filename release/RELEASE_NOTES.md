# Veldigo v0.2.0 — Preview 1

Android and Windows preview build of the Veldigo local password manager.

## Packages
- `Veldigo-Android.apk` — Android preview APK
- `Veldigo-Android.aab` — Android preview app bundle
- `Veldigo-portable.exe` — standalone self-extracting Windows launcher
- `Veldigo-Setup.exe` — Windows per-user installer
- `Veldigo-Windows-portable.zip` — portable Windows app folder
- `Android-SHA256.txt`, `Windows-SHA256.txt` — binary checksums

## Main features
Offline encrypted vault, password record editing, categories, favorites,
generator, secure notes, cards, manual TOTP, security overview and encrypted
backup/restore. Android window capture is blocked. Windows opens in a
resizable window, not full-screen.

## Important precautions
This is a **preview**, not a completed security audit or pixel-perfect signoff.
Please do not store irreplaceable production credentials in it.

**Android preview packages use temporary build signing** unless dedicated
upload-signing secrets are configured. Do not upload the AAB to Google Play
as a long-term production release or replace an app signed with another key.

**Windows builds are not Authenticode-signed.** Windows SmartScreen may
warn on first launch. The portable launcher extracts the bundled Windows
Flutter executable and DLLs to a versioned local cache, without a setup wizard.
The vault itself remains in the application's OS-managed storage.

Local backup snapshots reduce risk but cannot protect against every hardware
failure. Export .veldigo backups and retain an independent copy and its
associated master password. A forgotten master password is not remotely resettable.

© Brendigo · Veldigo
