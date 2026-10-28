import 'dart:io';
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

  File get pending => File('${primary.path}.pending');
  File get swap => File('${primary.path}.swap');
  File get previous => File('${primary.path}.bak');
  File get older => File('${primary.path}.bak2');
  File get quarantine => File('${primary.path}.corrupt');
  File get recoveryStage => File('${primary.path}.recovery');

  Future<bool> get hasAny async =>
      await primary.exists() || await swap.exists() ||
      await previous.exists() || await older.exists() ||
      await pending.exists() || await quarantine.exists() ||
      await recoveryStage.exists();

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
      final existing = await recoveryStage.readAsBytes();
      if (!listEquals(existing, encryptedBytes)) {
        // An interrupted earlier recovery can hold a different, potentially
        // newer vault. Never silently destroy that candidate.
        throw const FileSystemException(
          'Pronađena je druga nepotvrđena oporavna datoteka.');
      }
    } else {
      await recoveryStage.writeAsBytes(encryptedBytes, flush: true);
    }
    final staged = await recoveryStage.readAsBytes();
    if (!listEquals(staged, encryptedBytes) || !await verify(staged)) {
      throw const FileSystemException('Oporavna datoteka nije potpuna.');
    }
    if (await primary.exists()) {
      throw const FileSystemException('Druga instanca je vratila trezor.');
    }
    await recoveryStage.rename(primary.path);
    final committed = await primary.readAsBytes();
    if (!listEquals(committed, encryptedBytes) || !await verify(committed)) {
      throw const FileSystemException('Naknadna provjera trezora nije uspjela.');
    }
  }

  /// Compatibility helper for verified, single-process recovery tests.
  /// The live vault calls restoreExactWhenMissing under a file lock instead.
  Future<void> recoverInterruptedReplacement() async {
    if (await primary.exists()) return;
    for (final candidate in [swap, previous, older, pending, recoveryStage]) {
      if (!await candidate.exists()) continue;
      final bytes = await candidate.readAsBytes();
      if (!await verify(bytes)) continue;
      await restoreExactWhenMissing(bytes);
      return;
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
    if (!listEquals(await temp.readAsBytes(), encryptedBytes) ||
        !await verify(await temp.readAsBytes())) {
      throw const FileSystemException('Provjera zapisane datoteke nije uspjela.');
    }

    // On an ordinary save, retain up to two verified previous generations.
    if (await primary.exists()) {
      final oldBytes = await primary.readAsBytes();
      if (await verify(oldBytes)) {
        if (await previous.exists()) {
          final previousBytes = await previous.readAsBytes();
          if (await verify(previousBytes)) {
            final nextOlder = File('${older.path}.new');
            await nextOlder.writeAsBytes(previousBytes, flush: true);
            if (!listEquals(await nextOlder.readAsBytes(), previousBytes)) {
              throw const FileSystemException('Sigurnosna kopija je nepotpuna.');
            }
            await _replace(nextOlder, older);
          }
        }
        final nextPrevious = File('${previous.path}.new');
        await nextPrevious.writeAsBytes(oldBytes, flush: true);
        if (!listEquals(await nextPrevious.readAsBytes(), oldBytes)) {
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
      if (!await verify(await primary.readAsBytes())) {
        throw const FormatException('Naknadna provjera nije uspjela.');
      }
    } catch (_) {
      if (await primary.exists()) await primary.delete();
      if (await swap.exists()) await swap.copy(primary.path);
      rethrow;
    }
    // Keep .swap as an additional recovery point until the next write.
  }

  Future<void> _replace(File newFile, File destination) async {
    if (await destination.exists()) await destination.delete();
    await newFile.rename(destination.path);
  }

  Future<List<File>> verifiedRecoveryFiles() async {
    final found = <File>[];
    for (final file in [swap, previous, older]) {
      if (await file.exists() && await verify(await file.readAsBytes())) {
        found.add(file);
      }
    }
    return found;
  }
}
