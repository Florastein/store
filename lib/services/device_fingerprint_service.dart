import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class DeviceFingerprintService {
  DeviceFingerprintService({
    required Future<SharedPreferences> preferences,
    Random? random,
  }) : _preferences = preferences,
       _random = random ?? Random.secure();

  static const _storageKey = 'otp_device_fingerprint';
  final Future<SharedPreferences> _preferences;
  final Random _random;

  Future<String> getFingerprint() async {
    final preferences = await _preferences;
    final existing = preferences.getString(_storageKey);
    if (existing != null && existing.length >= 20) {
      return existing;
    }

    final fingerprint = List.generate(
      32,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await preferences.setString(_storageKey, fingerprint);
    return fingerprint;
  }
}
