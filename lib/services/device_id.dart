import 'dart:math';
import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';

class DeviceId {
  static const _prefsKey = 'device_id_v1';
  static String? _cached;

  static Future<String> getId() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey);
    if (existing != null && existing.isNotEmpty) {
      return _cached = existing;
    }
    final os = _platformTag();
    final id = '${os}_${_randomBase36(16)}';
    await prefs.setString(_prefsKey, id);
    _cached = id;
    return id;
  }

  static String _platformTag() {
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
    } catch (_) {}
    return 'unknown';
  }

  static String _randomBase36(int length) {
    const chars = '0123456789abcdefghijklmnopqrstuvwxyz';
    final rand = Random.secure();
    return List.generate(
      length,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }
}
