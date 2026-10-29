# Veldigo — security and privacy audit

**Audit date:** 29 October 2026  
**Scope:** Android + Windows Flutter application, encryption/backup engine, user-facing secret flows, native launchers, packaging and CI.  
**Method:** source-code inspection, control/data-flow review, threat analysis, and newly added regression tests. CI build results must be read separately. **Not** a third-party penetration test, device forensics review, formal cryptographic proof, or certification.

## Asset and threat model

Protected data: master password, decrypted vault records, TOTP seeds, card details, generated passwords and encrypted backup archives. Main threat scenarios: interrupted file replacement, stale concurrent writers, malformed imports, altered Windows portable installation, malicious clipboard observers, untrusted local files, disk corruption, malware, unattended unlocked app and misplaced backups.

Vault file format: Argon2id (19 MiB, 2 iterations, p=1) derives a key from a per-vault random 16-byte salt; AES-256-GCM encrypts JSON records using a random nonce and version-specific authenticated associated data. Main ciphertext is kept in user-local application support storage. No remote reset or background cloud synchronization is implemented.

## Findings and remediation

| Priority | Finding | Fix / status |
|---|---|---|
| High | Commands already queued before a user lock could start after that lock, and their old unlock request could unexpectedly reopen the vault | **Fixed:** capture session epoch at API invocation, before entering the serialized queue; cancel queued unlock/create/first-import/recovery requests from older sessions; targeted queued-unlock test |
| Medium | Closing a window while Argon2/disk IO was pending could notify a disposed `ChangeNotifier` and revive previous session state | **Fixed:** `dispose()` invalidates the session, wipes application-level references and guards every UI notification; disposal race regression test |
| High | User locking the vault while unlock, backup import, key rotation or recovery was asynchronously awaiting disk/KDF operations could re-establish keys or plaintext in memory | **Fixed:** session-epoch cancellation, guarded state transitions, and per-transaction authenticated keys for disk verification; regression tests for interrupted unlock/import/key changes/writes |
| Medium | Local main vault and crash-recovery files could grow after file metadata checks and trigger unbounded memory allocations | **Fixed:** streaming reads capped at 64 MiB, including rotating and quarantined snapshots; overlarge candidates skipped without deleting other recovery versions |
| Medium | Valid encrypted data quarantined after failed authentication or key rotation could be inaccessible when the primary vault was missing | **Fixed:** authenticated quarantine included as a last-resort recovery source; tests ensure corrupt quarantined bytes cannot create a vault |
| Medium | Windows vault remained unlocked on focus loss without a paused/hidden lifecycle transition | **Fixed:** Windows inactive/focus loss now locks except during a user-initiated, bounded native file picker |
| High | Crash during backup generation replacement could delete an older valid checkpoint before the new one is promoted | **Changed:** backup destinations move to verified, recoverable `.retired` generations; failed promotion restores the predecessor. Added rotation/recovery regression tests |
| High | Cached portable Windows files were executed if `veldigo.exe` merely existed | **Changed:** launcher validates every embedded-release file against an internal SHA-256 manifest, rejects additional files and extracts a fresh verified copy when cache integrity fails |
| High | Android backup imports loaded arbitrary picker bytes into memory before enforcing vault size | **Changed:** both first-run import and recovery use one bounded 64 MiB reader that streams local selections, checks metadata and actual byte count |
| Medium | TOTP key parsing lacked strict Base32 length/trailing-bit validation and formal vectors | **Changed:** shared TOTP implementation and RFC 6238 SHA-1 test vectors for 6-digit output |
| Medium | In-flight encrypted vault recovery could associate decrypted memory with another on-disk generation | **Changed in earlier PR #4 commits:** restore the *same authenticated* ciphertext under an exclusive inter-process file lock |
| Medium | Android import/export could be interrupted by automatic background locking | **Changed in earlier PR #4 commits:** two-minute scoped file-picker grace, expiry enforcement on resume |
| Medium | Inactive biometric/cloud/QR roadmap labels appeared in app screens | **Changed:** removed inactive controls and roadmap copy. Do not present unavailable features as usable |
| Medium | Android privacy rules were applied only by preparation scripts on certain builds | **Changed in earlier PR #4 commits:** version-controlled manifest and backup exclusion XML, with regression tests |
| Medium | Published unreviewed advisory [CVE-2026-38093](https://github.com/advisories/GHSA-r2rg-pm28-j8gw) describes an Android path traversal issue affecting `file_picker` through 10.3.10 | **Changed:** migrated to `file_picker` 13.3.0 and a federated Android implementation, with bounded streaming imports. The advisory does not designate a fixed version; independently verify the Android native path handling before signoff |
| High | Old mobile details dialog could retain an erased record's display and stay above an app-lock screen | **Changed:** full-screen live account details follow the current encrypted store, immediately show a non-secret placeholder for permanently erased records, and close all detail/editor routes when the vault locks; added privacy widget regression |
| High | Revealed password UI state could be reused when a different account was selected | **Changed:** record-specific keyed secret widgets reset visibility on account or secret change; added regression test |
| Low | Error path in backup-restore dialog retained a text controller longer than necessary | **Changed:** controller disposed using `finally` even on failed restore |
| Low | Unused generated Windows symlinks, local Android SDK path, old branding mockups and obsolete scaffold automation were checked in | **Changed:** remove from branch and ignore disposable files |

## Controls reviewed

- **Cryptography:** encrypted-at-rest vault; authenticated decryption; wrong password/integrity errors; cryptographically random salt and nonce; password generator uses system CSPRNG.
- **Storage:** session invalidation prevents unlocking secrets after a user lock. Encrypted checkpoint validation is bound to the transaction's original key. Storage serializes same-instance mutations, uses a cross-process lock and committed digest to refuse stale writes. Keeps encrypted crash-recovery generations; separate independent backups remain necessary.
- **Privacy:** Android `FLAG_SECURE`; OS automatic backup/device transfer exclusions; cleartext network disallowed; immediate background lock except a bounded native picker operation.
- **Inputs:** account IDs checked for duplicates, backups limited, corrupted ciphertext rejected, TOTP seeds parsed locally.
- **UI safety:** secret fields hidden by default; failed credential saves retain the editing form; destructive vault restore requires confirmation; deleting an entry moves it to encrypted Trash; permanent deletion has a second confirmation.
- **Distribution:** release pipeline checks analyses/tests before artifacts; source ZIP and published SHA-256 files are not a substitute for authenticated publisher signatures.

## Open risks — do not describe as complete or production-grade

1. **High:** Android artifacts still need the developer's own securely managed Google Play upload keystore; Windows binaries need Authenticode signing. No release authenticity guarantee until signing/provenance validation is implemented.
2. **High:** No independent penetration test, cryptographic audit, native device crash/ANR testing or filesystem power-failure testing. A passed unit test cannot guarantee zero credential loss.
3. **Medium:** Secret strings and keys may remain in Dart-managed memory or in-flight cryptographic closures even after app-level locking; zeroization is not guaranteed. Endpoint malware can inspect process memory, simulate input or read clipboard contents.
4. **Medium:** Windows lacks a native analogue to Android `FLAG_SECURE`. Screenshots, remote-screen capture and accessibility tools may expose secrets while unlocked.
5. **Medium:** Cached encrypted snapshots and archives under *old* master passwords remain recoverable; password changes cannot revoke prior independently exported archives. Define an explicit safe backup-retention policy before enterprise use.
6. **Medium:** Provider-specific file-picking behavior, clipboard clearing and UI lock transitions need hardware testing on supported Android API levels and Windows editions.
7. **Medium:** Targeted advisory review identified the previous `file_picker` vulnerability. Complete transitive SCA, license compliance and supply-chain attestation have **not** been independently completed; `flutter stable`, Inno Setup fallback and CI actions may change without build pinning.
8. **Medium:** Card/CVV storage is not a PCI DSS compliance claim. Evaluate data-retention requirements and product scope before production distribution.
9. **Low:** Password-strength scoring is a local heuristic, not a compromised-password or 2FA-status lookup. Keep that limitation clear to users.

## Further checks for concurrency

Queued operations are bound to the session present when the user invoked them, not the session when they eventually reach the asynchronous queue. Disposed stores do not notify Flutter widgets after their lifetime.

All in-flight operations started in a prior user session must fail closed when the lock epoch changes. Durable ciphertext may still reflect a write that was already in progress before locking; the critical invariant is that no obsolete asynchronous callback can restore a key or plaintext into the active UI. Test the same behavior under real Android activity switches, Windows focus changes and application shutdown.

## Validation gates

Run `flutter pub get`, `flutter analyze`, `flutter test`, Android/Windows builds, Windows portable manifest verification, and re-check CI run SHA. Additional manual checks: interrupted rename on disk, 2-instance writes, corrupted `.pending` and `.retired` files, 64 MiB+ imported archives, expired picker grace, Android backgrounding, Windows portable tampering, cross-device encrypted backup restore, screenshots at reference DPIs, Android crash/ANR reports and actual OS permissions.

**Conclusion:** the documented high-impact issues above were addressed in source code, with tests for key scenarios. The application must remain labeled **preview / security review incomplete** until residual verification and signing are finished.

## v0.2.6 follow-up — 29 October 2026

- **High: backups written after master-key rotation.** Previously a current-key backup rotation could refuse to replace a backup encrypted with the *previous* master key when an existing `.retired` checkpoint was present. The writer now keeps that retired ciphertext under a distinct `.retired-legacy-<timestamp>` name rather than discarding it or blocking subsequent writes. Both recovery scans include the preserved files, and the existing KDF, AES-GCM envelope and vault schema are unchanged. The new `test/vault_post_rotation_write_test.dart` covers six pre-rotation saves, rotation, three post-rotation saves, and re-unlocking all records. These legacy files still require their corresponding old password; they are deliberately not decrypted with a new password.
- **High: unlocked modal after vault lock.** A Flutter `Navigator` dialog remains above its home route even when the home is rebuilt to show the unlock screen. `lib/main.dart` now watches the unlocked→locked transition and dismisses every nested sensitive route after that frame; `test/lock_dismisses_sensitive_routes_test.dart` exercises an open password editor on lock.
- **Recovery storage:** distinct legacy snapshots are retained intentionally, so disk usage can grow when rotating master keys. They remain encrypted and are not automatically uploaded. Assess disk-space and retention UX before production; never silently erase old-key recovery material without explicit user permission.
- **Verification scope:** source review and automated tests only. No physical Android/Windows device, penetration test, power-loss injection or independent crypto audit is claimed by this follow-up. See the PR's current GitHub Actions run for actual pass/fail state.


## v0.2.9 follow-up — native picker session isolation (29 October 2026)

- **High: stale file-picker grace after manual lock.** Before this fix, `lock()` and `dispose()` invalidated the vault session but left `_externalPickerDepth` and `_externalPickerStarted` untouched. If a native picker outlived the lock and the user unlocked again, the old picker state could authorize a background-lock grace period in the new session. Its late `finally` could also decrement the depth of an unrelated picker.
- **Code change:** reset the picker depth and timestamp whenever the session is invalidated, scope picker completion and timeout to the exact originating session epoch, and reject picker results that arrive after lock/dispose. Stale cleanup never mutates a new session's picker state.
- **Regression coverage:** `test/vault_file_picker_privacy_test.dart` now covers cancellation on lock, stale completion after a new unlock, independent timeout ownership, and overlapping pickers within one session.
- **Compatibility:** no encrypted vault format, master-password KDF, user data, or backup envelope changes. **Verification:** CI, native file-picker integration tests on Android/Windows, and physical-device background/foreground QA are still required before production signoff.
