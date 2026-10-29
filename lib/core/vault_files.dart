import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Crash-tolerant persistence for *already encrypted* vault bytes.
///
/// The primary file is never truncated in place. Before replacement the old
/// primary is copied into a rotating recovery set. Candidate bytes are
/// checked before and after installation. Files must reside on one volume.
/// These guarantees do not extend to disk failure, filesystem corruption,
/// malware, or cloud cleanup; users still need offline encrypted backups.
class VaultFiles {
  final File primary;
  final Future<bool> Function(List<int> bytes) verify;
  VaultFiles(this.primary, {required this.verify});

  static const _maxEncryptedBytes = 64 * 1024 * 1024;

  /// Never eagerly load an attacker-modified or concurrently growing recovery
  /// file; this limit also applies to every intermediate backup generation.
  Future<List<int>> _readBounded(File file) async {
    if (!await file.exists() ||
        await file.length() > _maxEncryptedBytes) {
      throw const FormatException('Šifrirana kopija je prevelika.');
    }
    final buffer = BytesBuilder(copy: false);
    await for (final chunk in file.openRead(0, _maxEncryptedBytes + 1)) {
      if (buffer.length + chunk.length > _maxEncryptedBytes) {
        throw const FormatException('Šifrirana kopija je prevelika.');
      }
      buffer.add(chunk);
    }
    return buffer.takeBytes();
  }

  File get pending => File('${primary.path}.pending');
  File get swap => File('${primary.path}.swap');
  File get previous => File('${primary.path}.bak');
  File get older => File('${primary.path}.bak2');
  File get quarantine => File('${primary.path}.corrupt');
  File get previousRetired => File('${previous.path}.retired');
  File get olderRetired => File('${older.path}.retired');
  File get recoveryStage => File('${primary.path}.recovery');

  Future<bool> get hasAny async =>
      await primary.exists() || await swap.exists() ||
      await previous.exists() || await older.exists() ||
      await pending.exists() || await quarantine.exists() ||
      await recoveryStage.exists() || await previousRetired.exists() ||
      await olderRetired.exists() ||
      (await _legacyRecoveryFiles()).isNotEmpty;

  /// Files from an older master-key generation cannot be authenticated using
  /// the current key. Retain them as encrypted recovery evidence rather than
  /// deleting them when rotating backup slots after password changes.
  Future<List<File>> _legacyRecoveryFiles() async {
    final archived = <File>[];
    if (!await primary.parent.exists()) return archived;
    await for (final entry in primary.parent.list(followLinks: false)) {
      if (entry is File &&
          entry.path.startsWith('${primary.path}.bak') &&
          entry.path.contains('.retired-legacy-')) {
        archived.add(entry);
      }
    }
    archived.sort((a, b) => b.path.compareTo(a.path));
    return archived;
  }

  /// Ordered local recovery candidates. The caller must authenticate each
  /// candidate using the user-supplied master password before restoring it.
  Future<List<File>> recoveryCandidates() async => [
    recoveryStage, swap, previous, older, previousRetired, olderRetired,
    quarantine, pending, ...await _legacyRecoveryFiles(),
  ];

  /// Complete a *specific authenticated* recovery checkpoint, never a
  /// different candidate selected by a subsequent directory scan.
  ///
  /// The caller is responsible for holding the cross-process write lock. The
  /// source checkpoints remain intact. The stage uses a same-directory rename
  /// so a crash cannot expose a partially copied primary vault.
  Future<void> restoreExactWhenMissing(List<int> encryptedBytes) async {
    if (await primary.exists()) {
      throw const FileSystemException('Trezor je već vraćen u drugom procesu.');
    }
    if (!await verify(encryptedBytes)) {
      throw const FormatException('Kopija ne prolazi provjeru autentikacije.');
    }
    if (await recoveryStage.exists()) {
      List<int>? existing;
      try {
        existing = await _readBounded(recoveryStage);
      } on FormatException {
        // Treat an oversized interrupted stage as corrupt, preserving it
        // in place as forensic material rather than reading it into RAM.
      }
      if (!listEquals(existing, encryptedBytes)) {
        if (existing != null && await verify(existing)) {
          // An interrupted earlier recovery may be newer. The caller must
          // authenticate that exact checkpoint rather than overwrite it.
          throw const FileSystemException(
            'Pronađena je druga valjana oporavna datoteka.');
        }
        // Preserve malformed bytes for manual investigation and allow
        // recovery from a different valid checkpoint to continue.
        final preserved = File('${primary.path}.recovery-corrupt-'
            '${DateTime.now().toUtc().microsecondsSinceEpoch}');
        await recoveryStage.rename(preserved.path);
        await recoveryStage.writeAsBytes(encryptedBytes, flush: true);
      }
    } else {
      await recoveryStage.writeAsBytes(encryptedBytes, flush: true);
    }
    final staged = await _readBounded(recoveryStage);
    if (!listEquals(staged, encryptedBytes) || !await verify(staged)) {
      throw const FileSystemException('Oporavna datoteka nije potpuna.');
    }
    if (await primary.exists()) {
      throw const FileSystemException('Druga instanca je vratila trezor.');
    }
    await recoveryStage.rename(primary.path);
    final committed = await _readBounded(primary);
    if (!listEquals(committed, encryptedBytes) || !await verify(committed)) {
      throw const FileSystemException('Naknadna provjera trezora nije uspjela.');
    }
  }

  /// Compatibility helper for verified, single-process recovery tests.
  /// The live vault calls restoreExactWhenMissing under a file lock instead.
  Future<void> recoverInterruptedReplacement() async {
    if (await primary.exists()) return;
    for (final candidate in await recoveryCandidates()) {
      if (!await candidate.exists()) continue;
      try {
        final bytes = await _readBounded(candidate);
        if (!await verify(bytes)) continue;
        await restoreExactWhenMissing(bytes);
        return;
      } on FormatException {
        // An invalid checkpoint must not hide a smaller, valid backup.
        continue;
      }
    }
  }

  /// Caller must serialize install operations; items are committed in memory
  /// only after this completes successfully.
  Future<void> install(List<int> encryptedBytes) async {
    if (!await verify(encryptedBytes)) {
      throw const FormatException('Neispravna šifrirana datoteka.');
    }
    final temp = pending;
    await temp.writeAsBytes(encryptedBytes, flush: true);
    final tempBytes = await _readBounded(temp);
    if (!listEquals(tempBytes, encryptedBytes) ||
        !await verify(tempBytes)) {
      throw const FileSystemException('Provjera zapisane datoteke nije uspjela.');
    }

    // On an ordinary save, retain up to two verified previous generations.
    if (await primary.exists()) {
      final oldBytes = await _readBounded(primary);
      if (await verify(oldBytes)) {
        if (await previous.exists()) {
          final previousBytes = await _readBounded(previous);
          if (await verify(previousBytes)) {
            final nextOlder = File('${older.path}.new');
            await nextOlder.writeAsBytes(previousBytes, flush: true);
            if (!listEquals(await _readBounded(nextOlder), previousBytes)) {
              throw const FileSystemException('Sigurnosna kopija je nepotpuna.');
            }
            await _replace(nextOlder, older);
          }
        }
        final nextPrevious = File('${previous.path}.new');
        await nextPrevious.writeAsBytes(oldBytes, flush: true);
        if (!listEquals(await _readBounded(nextPrevious), oldBytes)) {
          throw const FileSystemException('Rezervna kopija je nepotpuna.');
        }
        await _replace(nextPrevious, previous);
      } else {
        // Never rotate a corrupt primary into a known-good backup slot.
        // Preserve the suspect ciphertext for manual forensic recovery.
        await primary.copy(quarantine.path);
      }
    }

    if (await swap.exists()) {
      // Previous recovery checkpoints are already copied to backups above.
      await swap.delete();
    }
    if (await primary.exists()) await primary.rename(swap.path);
    try {
      await temp.rename(primary.path);
      if (!await verify(await _readBounded(primary))) {
        throw const FormatException('Naknadna provjera nije uspjela.');
      }
    } catch (_) {
      if (await primary.exists()) await primary.delete();
      if (await swap.exists()) await swap.copy(primary.path);
      rethrow;
    }
    // Keep .swap as an additional recovery point until the next write.
  }

  /// Rotate snapshots without deleting the only previous on-disk generation
  /// before the new one has been committed. The retired file remains a
  /// recoverable checkpoint if power is lost between renames.
  Future<void> _replace(File newFile, File destination) async {
    final retired = File('${destination.path}.retired');
    var moved = false;
    if (await destination.exists()) {
      if (await retired.exists()) {
        // A previous backup may belong to the OLD master password after key
        // rotation. It must not block new saves or be silently discarded.
        // Keep the existing retired ciphertext as an immutable legacy copy.
        if (await verify(await _readBounded(destination))) {
          await retired.delete();
        } else {
          final legacy = File('${retired.path}-legacy-'
              '${DateTime.now().toUtc().microsecondsSinceEpoch}');
          await retired.rename(legacy.path);
        }
      }
      await destination.rename(retired.path);
      moved = true;
    }
    try {
      await newFile.rename(destination.path);
      if (!await verify(await _readBounded(destination))) {
        throw const FormatException('Rezervna kopija nije valjana.');
      }
    } catch (_) {
      if (moved && await retired.exists()) {
        if (await destination.exists()) await destination.delete();
        await retired.rename(destination.path);
      }
      rethrow;
    }
  }

  Future<List<File>> verifiedRecoveryFiles() async {
    final found = <File>[];
    for (final file in await recoveryCandidates()) {
      if (!await file.exists()) continue;
      try {
        if (await verify(await _readBounded(file))) found.add(file);
      } on FormatException {
        // Preserve but do not trust oversized/corrupt recovery material.
      }
    }
    return found;
  }
}
