import 'dart:async';

import 'package:flutter/services.dart';

/// A single time-limited clipboard owner for credentials and TOTP codes.
///
/// Only clears text if it still matches our most recent sensitive copy.
/// A lock also invalidates a copy that is still awaiting the platform channel.
/// This keeps clipboard management local and does not persist any secret.
abstract final class SensitiveClipboard {
  static int _generation = 0;
  static String? _lastValue;
  static Timer? _timer;

  static Future<void> copy(String value,
      {Duration expiry = const Duration(seconds: 30)}) async {
    if (value.isEmpty) return;
    final generation = ++_generation;
    _timer?.cancel();
    _timer = null;
    // Register before awaiting the OS, so lock() can revoke an in-flight copy.
    _lastValue = value;
    try {
      await Clipboard.setData(ClipboardData(text: value));
    } catch (_) {
      if (generation == _generation) _lastValue = null;
      rethrow;
    }
    if (generation != _generation) {
      // The copy returned after lock or was superseded by a newer copy.
      await _clearIfUnchanged(value);
      return;
    }
    _timer = Timer(expiry, () {
      unawaited(clear());
    });
  }

  /// Called as soon as a vault locks or the app is disposed.
  /// Clipboard errors are deliberately non-fatal on background platforms.
  static Future<void> clear() async {
    final previous = _lastValue;
    _generation++;
    _lastValue = null;
    _timer?.cancel();
    _timer = null;
    if (previous != null) await _clearIfUnchanged(previous);
  }

  static Future<void> _clearIfUnchanged(String value) async {
    try {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == value) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    } catch (_) {
      // OS clipboard services can be unavailable when the app is backgrounded.
    }
  }
}
