import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'vault_files.dart';
import 'vault_item.dart';

/// Encrypted, offline-first vault. File mutations are serialized and memory
/// state changes only *after* ciphertext was durably written and verified.
/// Always keep an independent exported encrypted backup as well.
class VaultStore extends ChangeNotifier {
  static const _memoryKiB = 19456;
  static const _iterations = 2;
  static const _parallelism = 1;
  static const _version = 1;
  static const _maxVaultBytes = 64 * 1024 * 1024;

  final File? vaultFileOverride;
  VaultStore({this.vaultFileOverride});

  final _cipher = AesGcm.with256bits();
  final _kdf = Argon2id(
    memory: _memoryKiB,
    iterations: _iterations,
    parallelism: _parallelism,
    hashLength: 32,
  );

  File? _file;
  VaultFiles? _files;
  SecretKey? _key;
  List<int>? _salt;
  List<VaultItem> _items = [];
  bool _exists = false;
  Future<void> _pending = Future<void>.value();
  // Every user-initiated lock invalidates every asynchronous operation started
  // in the previous unlocked session, including imports and master-key changes.
  int _sessionEpoch = 0;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    // The operating system can close a window while encryption is awaiting
    // KDF or disk IO. Dispose must invalidate callbacks without notifying
    // listeners that are already being unmounted.
    _disposed = true;
    _sessionEpoch++;
    _externalPickerTimeout?.cancel();
    _externalPickerTimeout = null;
    _key = null;
    _salt = null;
    _items = [];
    _committedHash = null;
    super.dispose();
  }


  void _assertNotCancelled(int epoch) {
    if (_disposed || epoch != _sessionEpoch) {
      throw const VaultSessionCancelledException();
    }
  }

  void _assertUnlockedSession(int epoch) {
    _assertNotCancelled(epoch);
    if (!isUnlocked) throw const VaultSessionCancelledException();
  }
  static const externalPickerGrace = Duration(minutes: 2);
  int _externalPickerDepth = 0;
  DateTime? _externalPickerStarted;
  Timer? _externalPickerTimeout;

  /// The system file picker uses another Android activity and can temporarily
  /// pause the Flutter app. Only this explicitly initiated operation can
  /// defer background locking, for at most two minutes.
  bool get externalPickerGraceActive =>
      isUnlocked && _externalPickerDepth > 0 &&
      _externalPickerStarted != null &&
      DateTime.now().difference(_externalPickerStarted!) < externalPickerGrace;

  bool get externalPickerExpired => _externalPickerDepth > 0 &&
      _externalPickerStarted != null &&
      DateTime.now().difference(_externalPickerStarted!) >= externalPickerGrace;

  Future<T> withExternalFilePicker<T>(Future<T> Function() action) async {
    if (!isUnlocked) throw StateError('Trezor je zaključan.');
    if (_externalPickerDepth++ == 0) {
      _externalPickerStarted = DateTime.now();
      _externalPickerTimeout = Timer(externalPickerGrace, () {
        if (_externalPickerDepth > 0 && isUnlocked) lock();
      });
    }
    try {
      return await action();
    } finally {
      _externalPickerDepth--;
      if (_externalPickerDepth == 0) {
        _externalPickerTimeout?.cancel();
        _externalPickerTimeout = null;
        _externalPickerStarted = null;
      }
    }
  }

  String? _committedHash;

  Future<String> _hash(List<int> bytes) async =>
      base64Encode((await Sha256().hash(bytes)).bytes);

  Future<void> _commitDigest(List<int> bytes, int session) async {
    final digest = await _hash(bytes);
    _assertNotCancelled(session);
    _committedHash = digest;
  }

  /// Prevent stale application instances from silently overwriting records.
  Future<void> _checkLatestOnDisk() async {
    final head = _committedHash;
    final file = _file;
    if (file == null) throw const VaultConflictException();
    if (head == null) {
      // A second process may have created a vault after our initial check.
      // Never allow it to be replaced by a stale first-run instance.
      if (await _files!.hasAny) throw const VaultConflictException();
      return;
    }
    if (!await file.exists()) throw const VaultConflictException();
    if (await _hash(await _readFile(file)) != head) {
      throw const VaultConflictException();
    }
  }

  bool get hasVault => _exists;
  bool get isUnlocked => _key != null;
  List<VaultItem> get items => List.unmodifiable(_items);

  // POSIX advisory locks may not exclude two handles from the same process.
  // Serialize all writes to one vault path in the current Dart isolate as
  // well; the existing OS file lock still guards separate app processes.
  static final Map<String, Future<void>> _processFileGates = {};

  static Future<T> _withProcessFileGate<T>(
      File file, Future<T> Function() operation) async {
    final path = file.absolute.path;
    final waiting = _processFileGates[path];
    final done = Completer<void>();
    final ours = done.future;
    _processFileGates[path] = ours;
    if (waiting != null) await waiting;
    try {
      return await operation();
    } finally {
      done.complete();
      if (identical(_processFileGates[path], ours)) {
        _processFileGates.remove(path);
      }
    }
  }

  Future<T> _serial<T>(Future<T> Function() operation) async {
    final waiting = _pending;
    final finished = Completer<void>();
    _pending = finished.future;
    await waiting;
    try {
      return await operation();
    } finally {
      finished.complete();
    }
  }

  Future<void> initialize() async {
    final File target;
    if (vaultFileOverride != null) {
      target = vaultFileOverride!;
    } else {
      final directory = await getApplicationSupportDirectory();
      target = File('${directory.path}${Platform.pathSeparator}veldigo.vault');
    }
    await target.parent.create(recursive: true);
    _file = target;
    _files = VaultFiles(target, verify: _canDecrypt);
    // Check for interrupted replacements, but never delete/move ciphertext
    // without the master password. Recovery happens after authentication.
    _exists = await _files!.hasAny;
    _notify();
  }

  List<int> _random(int count) {
    final random = Random.secure();
    return List<int>.generate(count, (_) => random.nextInt(256));
  }

  Future<SecretKey> _derive(String password, List<int> salt) {
    if (password.isEmpty) throw ArgumentError('Glavna lozinka je obavezna.');
    return _kdf.deriveKeyFromPassword(password: password, nonce: salt);
  }

  Future<void> create(String password) {
    final session = _sessionEpoch;
    return _serial(() async {
      _assertNotCancelled(session);
    if (_files == null) throw StateError('Trezor nije inicijaliziran.');
    if (_exists || await _files!.hasAny) {
      throw StateError('Trezor već postoji i neće biti prepisan.');
    }
    if (password.runes.length < 12) {
      throw ArgumentError('Glavna lozinka treba najmanje 12 znakova.');
    }
    final newSalt = _random(16);
    final newKey = await _derive(password, newSalt);
    _assertNotCancelled(session);
    _salt = newSalt;
    _key = newKey;
    try {
      await _persist(const <VaultItem>[]);
      _assertUnlockedSession(session);
      _items = [];
      _exists = true;
      _notify();
    } catch (_) {
      lock();
      rethrow;
    }
    });
  }

  Future<({SecretKey key, List<int> salt, List<VaultItem> items})>
      _decode(String source, String password) async {
    final envelope = jsonDecode(source) as Map<String, dynamic>;
    final salt = base64Decode(envelope['salt'] as String);
    if (salt.length != 16) throw const FormatException('Neispravan salt.');
    final key = await _derive(password, salt);
    final items = await _decodeWithKey(source, key);
    return (key: key, salt: salt, items: items);
  }

  Future<List<VaultItem>> _decodeWithKey(String source, SecretKey key) async {
    final envelope = jsonDecode(source) as Map<String, dynamic>;
    if (envelope['version'] != _version ||
        envelope['kdf'] != 'argon2id-19456-2-1' ||
        envelope['cipher'] != 'aes-256-gcm') {
      throw const FormatException('Nepodržana verzija trezora.');
    }
    final salt = base64Decode(envelope['salt'] as String);
    final nonce = base64Decode(envelope['nonce'] as String);
    final mac = base64Decode(envelope['mac'] as String);
    final cipherText = base64Decode(envelope['cipherText'] as String);
    if (salt.length != 16 || nonce.length != 12 || mac.length != 16 ||
        cipherText.length > _maxVaultBytes) {
      throw const FormatException('Neispravna datoteka trezora.');
    }
    final plaintext = await _cipher.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: key, aad: utf8.encode('veldigo-v1'),
    );
    final parsed = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
    final records = parsed['items'] as List<dynamic>;
    if (records.length > 100000) {
      throw const FormatException('Previše unosa.');
    }
    final result = records
        .map((record) => VaultItem.fromJson(record as Map<String, dynamic>))
        .toList();
    // A duplicate ID is ambiguous and could hide records in the UI.
    if (result.map((item) => item.id).toSet().length != result.length) {
      throw const FormatException('Duplicirani identifikatori unosa.');
    }
    return result;
  }

  /// Each write verifies ciphertext against the key that started it.
  /// User-initiated locking must not corrupt an in-progress disk rotation.
  Future<bool> _canDecryptUsingKey(List<int> bytes, SecretKey key) async {
    if (bytes.isEmpty || bytes.length > _maxVaultBytes) return false;
    try {
      await _decodeWithKey(utf8.decode(bytes), key);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _canDecrypt(List<int> bytes) async {
    final key = _key;
    return key != null && await _canDecryptUsingKey(bytes, key);
  }

  Future<List<int>> _readFile(File source) async {
    if (!await source.exists() || await source.length() > _maxVaultBytes) {
      throw const FormatException('Datoteka trezora nije dostupna.');
    }
    // Do not trust file metadata alone: a corrupted or concurrently enlarged
    // vault must never trigger an unbounded allocation in a password manager.
    final output = BytesBuilder(copy: false);
    await for (final chunk in source.openRead(0, _maxVaultBytes + 1)) {
      if (output.length + chunk.length > _maxVaultBytes) {
        throw const FormatException('Datoteka trezora je prevelika.');
      }
      output.add(chunk);
    }
    if (output.length == 0) {
      throw const FormatException('Datoteka trezora je prazna.');
    }
    return output.takeBytes();
  }

  Future<void> unlock(String password) {
    final session = _sessionEpoch;
    return _serial(() async {
      _assertNotCancelled(session);
    final file = _file;
    final files = _files;
    if (file == null || files == null || !_exists) {
      throw StateError('Trezor ne postoji.');
    }

    // Serialize recovery with writers in other processes. Otherwise a
    // verified backup and the re-created primary may refer to different
    // generations of the vault.
    final guard = await File('${file.path}.write-lock')
        .open(mode: FileMode.append);
    try {
      await guard.lock(FileLock.exclusive);
      if (await file.exists()) {
        final bytes = await _readFile(file);
        final opened = await _decode(utf8.decode(bytes), password);
        _assertNotCancelled(session);
        _key = opened.key;
        _salt = opened.salt;
        _items = opened.items;
        await _commitDigest(bytes, session);
      } else {
        bool restored = false;
        for (final candidate in await files.recoveryCandidates()) {
          if (!await candidate.exists()) continue;
          try {
            final bytes = await _readFile(candidate);
            final opened = await _decode(utf8.decode(bytes), password);
            _assertNotCancelled(session);
            _key = opened.key;
            _salt = opened.salt;
            // Must install precisely this authenticated ciphertext.
            await VaultFiles(file,
                verify: (candidate) => _canDecryptUsingKey(candidate, opened.key))
                .restoreExactWhenMissing(bytes);
            _assertNotCancelled(session);
            final committed = await _readFile(file);
            if (!listEquals(committed, bytes)) {
              throw const FileSystemException(
                'Sadržaj trezora promijenio se tijekom oporavka.');
            }
            _items = opened.items;
            await _commitDigest(committed, session);
            restored = true;
            break;
          } on VaultSessionCancelledException {
            rethrow;
          } on FileSystemException {
            // Abort instead of silently choosing a different generation.
            rethrow;
          } catch (_) {
            // A corrupted checkpoint or a snapshot from a previous master
            // password is not proof that the remaining backups are invalid.
            _key = null;
            _salt = null;
          }
        }
        if (!restored) throw const VaultAuthenticationException();
      }
      _assertNotCancelled(session);
      _notify();
    } on VaultSessionCancelledException {
      lock();
      rethrow;
    } catch (_) {
      lock();
      throw const VaultAuthenticationException();
    } finally {
      await guard.unlock();
      await guard.close();
    }
    });
  }

  /// Deliberately separate from unlock: never silently replace an existing
  /// primary with an older version when the user typed an old password.
  Future<void> recoverFromLocalBackup(String password) {
    final session = _sessionEpoch;
    return _serial(() async {
      _assertNotCancelled(session);
    final files = _files;
    final primary = _file;
    if (files == null || primary == null || !_exists) {
      throw StateError('Trezor ne postoji.');
    }
    final initialPrimary = await primary.exists()
        ? await _hash(await _readFile(primary)) : null;
    for (final candidate in await files.recoveryCandidates()) {
      if (!await candidate.exists()) continue;
      try {
        final bytes = await _readFile(candidate);
        final decoded = await _decode(utf8.decode(bytes), password);
        _assertNotCancelled(session);
        // This is a user-approved rollback. It is not a license to erase
        // changes made concurrently by a different running instance.
        final guard = await File('${primary.path}.write-lock')
            .open(mode: FileMode.append);
        try {
          await guard.lock(FileLock.exclusive);
          final current = await primary.exists()
              ? await _hash(await _readFile(primary)) : null;
          if (current != initialPrimary) {
            throw const VaultConflictException();
          }
          _assertNotCancelled(session);
          final previousKey = _key;
          final previousSalt = _salt;
          _key = decoded.key;
          _salt = decoded.salt;
          try {
            await VaultFiles(primary,
              verify: (candidate) => _canDecryptUsingKey(candidate, decoded.key))
                .install(bytes);
            _assertNotCancelled(session);
            await _commitDigest(bytes, session);
          } catch (_) {
            if (_sessionEpoch == session) {
              _key = previousKey;
              _salt = previousSalt;
            }
            rethrow;
          }
        } finally {
          await guard.unlock();
          await guard.close();
        }
        _assertNotCancelled(session);
        _items = decoded.items;
        _exists = true;
        _notify();
        return;
      } on VaultConflictException {
        lock();
        rethrow;
      } on VaultSessionCancelledException {
        rethrow;
      } catch (_) {
        // Only try an older candidate on authentication / IO failure.
      }
    }
    lock();
    throw const VaultAuthenticationException();
    });
  }

  void lock() {
    _sessionEpoch++;
    _externalPickerTimeout?.cancel();
    _externalPickerTimeout = null;
    _key = null;
    _salt = null;
    _items = [];
    _committedHash = null;
    _notify();
  }

  Future<void> _persist(List<VaultItem> entries) async {
    final session = _sessionEpoch;
    final key = _key;
    final salt = _salt;
    final files = _files;
    if (key == null || salt == null || files == null) {
      throw StateError('Trezor je zaključan.');
    }
    final box = await _cipher.encrypt(
      utf8.encode(VaultItem.encodeAll(entries)),
      secretKey: key,
      aad: utf8.encode('veldigo-v1'),
    );
    final bytes = utf8.encode(jsonEncode({
      'version': _version,
      'kdf': 'argon2id-19456-2-1',
      'cipher': 'aes-256-gcm',
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
      'cipherText': base64Encode(box.cipherText),
    }));
    await _withProcessFileGate(_file!, () async {
      final lockFile = File('${_file!.path}.write-lock');
      final guard = await lockFile.open(mode: FileMode.append);
      try {
        await guard.lock(FileLock.exclusive);
        await _checkLatestOnDisk();
        _assertUnlockedSession(session);
        await VaultFiles(_file!,
          verify: (candidate) => _canDecryptUsingKey(candidate, key))
            .install(bytes);
        await _commitDigest(bytes, session);
      } finally {
        await guard.unlock();
        await guard.close();
      }
    });
  }

  Future<void> save() => _serial(() async {
    await _persist(List<VaultItem>.of(_items));
    _exists = true;
    _notify();
  });

  Future<void> put(VaultItem item) => _serial(() async {
    if (!isUnlocked) throw StateError('Trezor je zaključan.');
    final next = List<VaultItem>.of(_items);
    final at = next.indexWhere((record) => record.id == item.id);
    if (at < 0) {
      next.add(item);
    } else {
      next[at] = item;
    }
    await _persist(next);
    if (isUnlocked) _items = next;
    _notify();
  });

  /// Delete is reversible: encrypted contents stay in the local trash.
  Future<void> remove(String id) => _serial(() async {
    if (!isUnlocked) throw StateError('Trezor je zaključan.');
    final next = List<VaultItem>.of(_items);
    final index = next.indexWhere((record) => record.id == id);
    if (index == -1) throw StateError('Zapis nije pronađen.');
    if (next[index].trashed) return;
    next[index] = next[index].copyWith(
      trashed: true, updatedAt: DateTime.now().toUtc());
    await _persist(next);
    if (isUnlocked) _items = next;
    _notify();
  });

  Future<void> restoreTrashed(String id) => _serial(() async {
    if (!isUnlocked) throw StateError('Trezor je zaključan.');
    final next = List<VaultItem>.of(_items);
    final index = next.indexWhere((record) => record.id == id);
    if (index == -1 || !next[index].trashed) {
      throw StateError('Zapis nije pronađen u Košu.');
    }
    next[index] = next[index].copyWith(
      trashed: false, updatedAt: DateTime.now().toUtc());
    await _persist(next);
    if (isUnlocked) _items = next;
    _notify();
  });

  /// Irreversible in the active vault, but encrypted historic copies may
  /// retain prior data until deliberately removed by the user.
  Future<void> permanentlyRemove(String id) => _serial(() async {
    if (!isUnlocked) throw StateError('Trezor je zaključan.');
    final existing = _items.where((record) => record.id == id).firstOrNull;
    if (existing == null || !existing.trashed) {
      throw StateError('Zapis mora najprije biti u Košu.');
    }
    final next = _items.where((record) => record.id != id).toList();
    await _persist(next);
    if (isUnlocked) _items = next;
    _notify();
  });

  Future<List<int>> encryptedBackup() => _serial(() async {
    if (!isUnlocked || _file == null) {
      throw StateError('Otključajte trezor prije izvoza.');
    }
    final bytes = await _readFile(_file!);
    if (!await _canDecrypt(bytes)) {
      throw const FormatException('Trezor nije valjan — izvoz prekinut.');
    }
    return bytes;
  });

  /// Allows a fresh installation to load an existing encrypted .veldigo
  /// archive without first generating a second (empty) vault.
  /// No existing ciphertext is ever replaced by this operation.
  Future<void> importFirstVault(
      List<int> bytes, String masterPassword) {
    final session = _sessionEpoch;
    return _serial(() async {
      _assertNotCancelled(session);
    final files = _files;
    final target = _file;
    if (files == null || target == null) {
      throw StateError('Trezor nije inicijaliziran.');
    }
    if (_exists || await files.hasAny || await target.exists()) {
      throw StateError('Postojeći trezor neće biti prepisan.');
    }
    if (bytes.length > _maxVaultBytes || bytes.isEmpty) {
      throw const FormatException('Datoteka sigurnosne kopije nije valjana.');
    }
    final imported = await _decode(utf8.decode(bytes), masterPassword);
    _assertNotCancelled(session);
    _key = imported.key;
    _salt = imported.salt;
    try {
      final lockFile = File('${target.path}.write-lock');
      final guard = await lockFile.open(mode: FileMode.append);
      try {
        await guard.lock(FileLock.exclusive);
        if (await files.hasAny) {
          throw const VaultConflictException();
        }
        _assertUnlockedSession(session);
        await VaultFiles(target,
            verify: (candidate) => _canDecryptUsingKey(candidate, imported.key))
              .install(bytes);
        await _commitDigest(bytes, session);
      } finally {
        await guard.unlock();
        await guard.close();
      }
      _assertUnlockedSession(session);
      _items = imported.items;
      _exists = true;
      _notify();
    } catch (_) {
      lock();
      rethrow;
    }
    });
  }

  /// Preserve and verify the existing ciphertext before destructive imports
  /// or master-key rotation. Backup remains encrypted under the old key.
  Future<void> _preserveVerifiedSnapshot(File source, String purpose) async {
    final original = await _readFile(source);
    if (!await _canDecrypt(original)) {
      throw const FormatException(
        'Aktualni trezor nije valjan. Spremanje nove verzije je prekinuto.');
    }
    final snapshot = File('${source.path}.$purpose-'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}');
    await snapshot.writeAsBytes(original, flush: true);
    if (!listEquals(original, await _readFile(snapshot))) {
      throw const FileSystemException(
        'Provjera zasebne šifrirane kopije nije uspjela.');
    }
  }

  Future<void> changeMasterPassword(
      String currentPassword, String newPassword) => _serial(() async {
    final session = _sessionEpoch;
    final file = _file;
    if (!isUnlocked || file == null) {
      throw StateError('Trezor je zaključan.');
    }
    if (newPassword.runes.length < 12) {
      throw ArgumentError('Nova glavna lozinka mora imati barem 12 znakova.');
    }
    // Authentication is required even while the current vault is unlocked.
    final current = await _decode(
      utf8.decode(await _readFile(file)), currentPassword);
    if (current.items.length != _items.length) {
      throw StateError('Trezor je izmijenjen izvan aplikacije.');
    }
    await _preserveVerifiedSnapshot(file, 'before-password-change');
    _assertUnlockedSession(session);
    final oldKey = _key;
    final oldSalt = _salt;
    final newSalt = _random(16);
    final newKey = await _derive(newPassword, newSalt);
    _assertUnlockedSession(session);
    _key = newKey;
    _salt = newSalt;
    try {
      await _persist(List<VaultItem>.of(_items));
      _assertUnlockedSession(session);
      _notify();
    } catch (_) {
      if (_sessionEpoch == session) {
        _key = oldKey;
        _salt = oldSalt;
      }
      rethrow;
    }
  });

  /// User confirmation happens in the UI. Original primary is also saved
  /// separately to protect against an accidentally imported older backup.
  Future<void> restore(List<int> bytes, String backupPassword) =>
      _serial(() async {
    final session = _sessionEpoch;
    final files = _files;
    final target = _file;
    if (files == null || target == null || !isUnlocked) {
      throw StateError('Najprije otključajte trezor.');
    }
    if (bytes.length > _maxVaultBytes) {
      throw const FormatException('Sigurnosna kopija je prevelika.');
    }
    final imported = await _decode(utf8.decode(bytes), backupPassword);
    _assertUnlockedSession(session);
    if (await target.exists()) {
      await _preserveVerifiedSnapshot(target, 'before-import');
    }
    _assertUnlockedSession(session);
    final oldKey = _key;
    final oldSalt = _salt;
    _key = imported.key;
    _salt = imported.salt;
    try {
      // The imported backup is intentionally allowed to differ from the
      // current primary, but still serializes against external writers.
      final lockFile = File('${target.path}.write-lock');
      final guard = await lockFile.open(mode: FileMode.append);
      try {
        await guard.lock(FileLock.exclusive);
        await _checkLatestOnDisk();
        _assertUnlockedSession(session);
        await VaultFiles(target,
          verify: (candidate) => _canDecryptUsingKey(candidate, imported.key))
            .install(bytes);
        await _commitDigest(bytes, session);
      } finally {
        await guard.unlock();
        await guard.close();
      }
      _assertUnlockedSession(session);
      _items = imported.items;
      _exists = true;
      _notify();
    } catch (_) {
      if (_sessionEpoch == session) {
        _key = oldKey;
        _salt = oldSalt;
      }
      rethrow;
    }
  });
}

class VaultSessionCancelledException implements Exception {
  const VaultSessionCancelledException();
  @override
  String toString() => 'Trezor je zaključan. Otključajte ga za nastavak.';
}

class VaultConflictException implements Exception {
  const VaultConflictException();
  @override
  String toString() => 'Trezor je promijenjen u drugom procesu. '
      'Ponovno ga otključajte prije spremanja.';
}

class VaultAuthenticationException implements Exception {
  const VaultAuthenticationException();
  @override
  String toString() =>
      'Neispravna lozinka ili oštećen trezor. Provjerite sigurnosnu kopiju.';
}
