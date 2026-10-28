import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
  String? _committedHash;

  Future<String> _hash(List<int> bytes) async =>
      base64Encode((await Sha256().hash(bytes)).bytes);

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
    notifyListeners();
  }

  List<int> _random(int count) {
    final random = Random.secure();
    return List<int>.generate(count, (_) => random.nextInt(256));
  }

  Future<SecretKey> _derive(String password, List<int> salt) {
    if (password.isEmpty) throw ArgumentError('Glavna lozinka je obavezna.');
    return _kdf.deriveKeyFromPassword(password: password, nonce: salt);
  }

  Future<void> create(String password) => _serial(() async {
    if (_files == null) throw StateError('Trezor nije inicijaliziran.');
    if (_exists || await _files!.hasAny) {
      throw StateError('Trezor već postoji i neće biti prepisan.');
    }
    if (password.runes.length < 12) {
      throw ArgumentError('Glavna lozinka treba najmanje 12 znakova.');
    }
    _salt = _random(16);
    _key = await _derive(password, _salt!);
    try {
      await _persist(const <VaultItem>[]);
      _items = [];
      _exists = true;
      notifyListeners();
    } catch (_) {
      lock();
      rethrow;
    }
  });

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

  Future<bool> _canDecrypt(List<int> bytes) async {
    final key = _key;
    if (key == null || bytes.isEmpty || bytes.length > _maxVaultBytes) {
      return false;
    }
    try {
      await _decodeWithKey(utf8.decode(bytes), key);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<int>> _readFile(File source) async {
    if (!await source.exists() || await source.length() > _maxVaultBytes) {
      throw const FormatException('Datoteka trezora nije dostupna.');
    }
    return source.readAsBytes();
  }

  Future<void> unlock(String password) => _serial(() async {
    final file = _file;
    final files = _files;
    if (file == null || files == null || !_exists) {
      throw StateError('Trezor ne postoji.');
    }
    try {
      if (await file.exists()) {
        final restored = await _decode(
          utf8.decode(await _readFile(file)), password);
        _key = restored.key;
        _salt = restored.salt;
        _items = restored.items;
        _committedHash = await _hash(await _readFile(file));
      } else {
        // The app may have been terminated between rename operations.
        // Authenticate candidates before restoring any missing primary.
        bool recovered = false;
        for (final source in [files.swap, files.previous, files.older,
            files.pending]) {
          if (!await source.exists()) continue;
          try {
            final bytes = await _readFile(source);
            final restored = await _decode(utf8.decode(bytes), password);
            _key = restored.key;
            _salt = restored.salt;
            await files.recoverInterruptedReplacement();
            if (!await file.exists()) continue;
            _items = restored.items;
            _committedHash = await _hash(await _readFile(file));
            recovered = true;
            break;
          } catch (_) { /* Try an older authenticated recovery copy. */ }
        }
        if (!recovered) throw const VaultAuthenticationException();
      }
      notifyListeners();
    } catch (_) {
      lock();
      throw const VaultAuthenticationException();
    }
  });

  /// Deliberately separate from unlock: never silently replace an existing
  /// primary with an older version when the user typed an old password.
  Future<void> recoverFromLocalBackup(String password) => _serial(() async {
    final files = _files;
    if (files == null || !_exists) throw StateError('Trezor ne postoji.');
    for (final candidate in [files.swap, files.previous, files.older]) {
      if (!await candidate.exists()) continue;
      try {
        final bytes = await _readFile(candidate);
        final decoded = await _decode(utf8.decode(bytes), password);
        final previousKey = _key;
        final previousSalt = _salt;
        _key = decoded.key;
        _salt = decoded.salt;
        try {
          await files.install(bytes);
        } catch (_) {
          _key = previousKey;
          _salt = previousSalt;
          rethrow;
        }
        _items = decoded.items;
        _committedHash = await _hash(await _readFile(_file!));
        _exists = true;
        notifyListeners();
        return;
      } catch (_) { /* Move to the next recovery generation. */ }
    }
    lock();
    throw const VaultAuthenticationException();
  });

  void lock() {
    _key = null;
    _salt = null;
    _items = [];
    _committedHash = null;
    notifyListeners();
  }

  Future<void> _persist(List<VaultItem> entries) async {
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
    final lockFile = File('${_file!.path}.write-lock');
    final guard = await lockFile.open(mode: FileMode.append);
    try {
      await guard.lock(FileLock.exclusive);
      await _checkLatestOnDisk();
      await files.install(bytes);
      _committedHash = await _hash(bytes);
    } finally {
      await guard.unlock();
      await guard.close();
    }
  }

  Future<void> save() => _serial(() async {
    await _persist(List<VaultItem>.of(_items));
    _exists = true;
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
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
      List<int> bytes, String masterPassword) => _serial(() async {
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
        await files.install(bytes);
        _committedHash = await _hash(bytes);
      } finally {
        await guard.unlock();
        await guard.close();
      }
      _items = imported.items;
      _exists = true;
      notifyListeners();
    } catch (_) {
      lock();
      rethrow;
    }
  });

  Future<void> changeMasterPassword(
      String currentPassword, String newPassword) => _serial(() async {
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
    final preserved = File('${file.path}.before-password-change-'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}');
    await file.copy(preserved.path);
    final oldKey = _key;
    final oldSalt = _salt;
    final newSalt = _random(16);
    final newKey = await _derive(newPassword, newSalt);
    _key = newKey;
    _salt = newSalt;
    try {
      await _persist(List<VaultItem>.of(_items));
      notifyListeners();
    } catch (_) {
      _key = oldKey;
      _salt = oldSalt;
      rethrow;
    }
  });

  /// User confirmation happens in the UI. Original primary is also saved
  /// separately to protect against an accidentally imported older backup.
  Future<void> restore(List<int> bytes, String backupPassword) =>
      _serial(() async {
    final files = _files;
    final target = _file;
    if (files == null || target == null || !isUnlocked) {
      throw StateError('Najprije otključajte trezor.');
    }
    if (bytes.length > _maxVaultBytes) {
      throw const FormatException('Sigurnosna kopija je prevelika.');
    }
    final imported = await _decode(utf8.decode(bytes), backupPassword);
    if (await target.exists()) {
      final copy = File('${target.path}.before-import-'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}');
      await target.copy(copy.path); // Encrypted original stays recoverable.
    }
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
        await files.install(bytes);
        _committedHash = await _hash(bytes);
      } finally {
        await guard.unlock();
        await guard.close();
      }
      _items = imported.items;
      _exists = true;
      notifyListeners();
    } catch (_) {
      _key = oldKey;
      _salt = oldSalt;
      rethrow;
    }
  });
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
