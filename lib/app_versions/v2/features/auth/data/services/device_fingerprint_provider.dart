import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Provides an install-scoped opaque identifier for signup anti-fraud checks.
/// It intentionally does not expose hardware identifiers or device details.
class DeviceFingerprintProvider {
  static const _storageKey = 'nanobio_install_fingerprint_v1';

  const DeviceFingerprintProvider();

  Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_storageKey)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final value = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    await prefs.setString(_storageKey, value);
    return value;
  }
}
