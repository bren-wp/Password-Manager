# Veldigo Security Notes

**Status:** early development build, NOT a completed or independently audited password manager.

## Current implementation

- Device-local AES-256-GCM encrypted JSON vault file.
- Argon2id KDF (19 MiB, 2 iterations, parallelism 1, 16-byte random salt).
- Random AEAD nonce for each save; versioned envelope with authenticated associated data.
- Credential records are not persisted as plaintext, and no network service is contacted.
- Locked state drops application-level references to vault contents and the key.
- Password generator uses `Random.secure()`.
- A .veldigo backup contains the existing encrypted vault; restoring validates it first.
- Clipboard copies from record detail are cleared after 30 seconds if unchanged.
- Files are written via temporary encrypted files and local rollback handling.
- Missing-primary recovery now authenticates and installs the **same** ciphertext
  under an exclusive cross-process lock, using a verified same-directory rename.
- A pre-existing valid recovery stage is not silently replaced by older data.
- Android and Windows vaults lock when the application is paused, hidden or detached.

## Known limitations — do not use for important credentials yet

1. The cryptography code has not completed external security review, cross-platform
   fault-injection tests, device security testing or penetration testing.
2. Dart-managed memory cannot guarantee immediate zeroization of secrets.
3. Android FLAG_SECURE is applied by platform bootstrap. Device-bound biometrics,
   Windows Hello and keychain integration are not implemented yet.
4. Clipboard clearing cannot protect against other applications observing clipboard.
5. TOTP supports manual Base32 seed input but not QR scanning.
6. Vault portability is via manual encrypted .veldigo export/import, not background sync.
7. File system permissions are inherited from OS application storage; OS backups and
   endpoint malware may expose ciphertext or plaintext while unlocked.
8. Password strength checks are a local heuristic; they do not check breach databases.
9. Backup restoration replaces the existing vault; make a copy before restoring.
10. The password KDF can be slow on low-end phones; parameters need benchmarking.
11. Windows does not yet have native prevention of screenshots, screen recording,
    hostile clipboard capture or memory inspection by software in the user session.
12. OS-level crash-consistency and hardware failure guarantees need independent
    power-loss testing; filesystems and storage controllers differ by platform.

Please report security bugs privately to the project maintainer rather than sharing secrets
in a public issue. Never commit real passwords, recovery material, signing keys or vaults.
