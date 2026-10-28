import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'vault_item.dart';

/// All credential data stays encrypted at rest. Nothing is sent to a server.
/// Version 1 format: Argon2id(19 MiB, t=2, p=1) + AES-256-GCM.
class VaultStore extends ChangeNotifier {
  static const _memoryKiB = 19456;
  static const _iterations = 2;
  static const _parallelism = 1;
  static const _version = 1;

  final _cipher = AesGcm.with256bits();
  final _kdf = Argon2id(
    memory: _memoryKiB,
    iterations: _iterations,
    parallelism: _parallelism,
    hashLength: 32,
  );

  File? _file;
  SecretKey? _key;
  List<int>? _salt;
  List<VaultItem> _items = [];
  bool _exists = false;

  bool get hasVault => _exists;
  bool get isUnlocked => _key != null;
  List<VaultItem> get items => List.unmodifiable(_items);

  Future<void> initialize() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    _file = File('${dir.path}${Platform.pathSeparator}veldigo.vault');
    // Restore interrupted atomic replacement only if the main file is absent.
    final backup = File('${_file!.path}.bak');
    if (!await _file!.exists() && await backup.exists()) {
      await backup.rename(_file!.path);
    }
    _exists = await _file!.exists();
    notifyListeners();
  }

  List<int> _random(int count) {
    final rand = Random.secure();
    return List<int>.generate(count, (_) => rand.nextInt(256));
  }

  Future<SecretKey> _derive(String password, List<int> salt) async {
    if (password.isEmpty) throw ArgumentError('Glavna lozinka je obavezna.');
    return _kdf.deriveKeyFromPassword(password: password, nonce: salt);
  }

  Future<void> create(String password) async {
    if (_file == null) throw StateError('Trezor nije inicijaliziran.');
    if (_exists) throw StateError('Trezor već postoji.');
    if (password.runes.length < 12) {
      throw ArgumentError('Glavna lozinka treba najmanje 12 znakova.');
    }
    final salt = _random(16);
    final key = await _derive(password, salt);
    _salt = salt;
    _key = key;
    _items = [];
    try {
      await save();
      _exists = true;
      notifyListeners();
    } catch (_) {
      lock();
      rethrow;
    }
  }

  Future<({SecretKey key, List<int> salt, List<VaultItem> items})>
      _decode(String source, String password) async {
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
        cipherText.length > 64 * 1024 * 1024) {
      throw const FormatException('Neispravna datoteka trezora.');
    }
    final key = await _derive(password, salt);
    final plain = await _cipher.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: key,
      aad: utf8.encode('veldigo-v1'),
    );
    final parsed = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    final entries = parsed['items'] as List<dynamic>;
    if (entries.length > 100000) throw const FormatException('Previše unosa.');
    return (
      key: key,
      salt: salt,
      items: entries
          .map((item) => VaultItem.fromJson(item as Map<String, dynamic>))
          .toList()
    );
  }

  Future<void> unlock(String password) async {
    if (_file == null || !_exists) throw StateError('Trezor ne postoji.');
    try {
      final result = await _decode(await _file!.readAsString(), password);
      _key = result.key;
      _salt = result.salt;
      _items = result.items;
      notifyListeners();
    } on SecretBoxAuthenticationError {
      throw const VaultAuthenticationException();
    } on FormatException {
      throw const VaultAuthenticationException();
    } on TypeError {
      throw const VaultAuthenticationException();
    }
  }

  void lock() {
    _key = null;
    _salt = null;
    _items = [];
    notifyListeners();
  }

  Future<void> save() async {
    final key = _key;
    final salt = _salt;
    final target = _file;
    if (key == null || salt == null || target == null) {
      throw StateError('Trezor je zaključan.');
    }
    final box = await _cipher.encrypt(
      utf8.encode(VaultItem.encodeAll(_items)),
      secretKey: key,
      aad: utf8.encode('veldigo-v1'),
    );
    final document = jsonEncode({
      'version': _version,
      'kdf': 'argon2id-19456-2-1',
      'cipher': 'aes-256-gcm',
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
      'cipherText': base64Encode(box.cipherText),
    });
    final temp = File('${target.path}.tmp');
    final backup = File('${target.path}.bak');
    await temp.writeAsString(document, flush: true);
    if (await backup.exists()) await backup.delete();
    if (await target.exists()) await target.rename(backup.path);
    try {
      await temp.rename(target.path);
    } catch (_) {
      if (!await target.exists() && await backup.exists()) {
        await backup.rename(target.path);
      }
      rethrow;
    }
    if (await backup.exists()) await backup.delete();
    _exists = true;
    notifyListeners();
  }

  Future<void> put(VaultItem item) async {
    if (!isUnlocked) throw StateError('Trezor je zaključan.');
    final old = List<VaultItem>.from(_items);
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index == -1) {
      _items.add(item);
    } else {
      _items[index] = item;
    }
    try {
      await save();
    } catch (_) {
      _items = old;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    if (!isUnlocked) throw StateError('Trezor je zaključan.');
    final old = List<VaultItem>.from(_items);
    _items.removeWhere((e) => e.id == id);
    try {
      await save();
    } catch (_) {
      _items = old;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<int>> encryptedBackup() async {
    if (!isUnlocked || _file == null) {
      throw StateError('Otključajte trezor prije izvoza.');
    }
    return _file!.readAsBytes();
  }

  /// A backup is authenticated BEFORE it replaces the current file.
  /// User must explicitly confirm replacement in the UI.
  Future<void> restore(List<int> bytes, String backupPassword) async {
    if (_file == null) throw StateError('Trezor nije inicijaliziran.');
    if (bytes.length > 64 * 1024 * 1024) {
      throw const FormatException('Sigurnosna kopija je prevelika.');
    }
    final content = utf8.decode(bytes);
    final decrypted = await _decode(content, backupPassword);
    final temp = File('${_file!.path}.tmp');
    final backup = File('${_file!.path}.bak');
    await temp.writeAsString(content, flush: true);
    if (await backup.exists()) await backup.delete();
    if (await _file!.exists()) await _file!.rename(backup.path);
    try {
      await temp.rename(_file!.path);
    } catch (_) {
      if (!await _file!.exists() && await backup.exists()) {
        await backup.rename(_file!.path);
      }
      rethrow;
    }
    if (await backup.exists()) await backup.delete();
    _key = decrypted.key;
    _salt = decrypted.salt;
    _items = decrypted.items;
    _exists = true;
    notifyListeners();
  }
}

class VaultAuthenticationException implements Exception {
  const VaultAuthenticationException();
  @override
  String toString() => 'Neispravna glavna lozinka ili oštećen trezor.';
}
