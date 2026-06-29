import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class SaleDeviceHashStore {
  static const _key = 'nanobio_sale_device_hash_v1';
  final Future<SharedPreferences> Function() preferencesFactory;
  final Random _random;

  SaleDeviceHashStore({
    Future<SharedPreferences> Function()? preferencesFactory,
    Random? random,
  }) : preferencesFactory = preferencesFactory ?? SharedPreferences.getInstance,
       _random = random ?? Random.secure();

  Future<String> readOrCreate() async {
    final preferences = await preferencesFactory();
    final existing = preferences.getString(_key)?.trim();
    if (existing != null && existing.length >= 24) return existing;

    final value = _newOpaqueDeviceHash();
    await preferences.setString(_key, value);
    return value;
  }

  String _newOpaqueDeviceHash() {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    return 'sale-device-${hex.join()}';
  }
}
