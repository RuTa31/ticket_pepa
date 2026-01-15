import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const _kTheme = 'app_theme_mode_v1';
  static const _kVibrate = 'app_vibrate_on_scan_v1';

  ThemeMode _themeMode = ThemeMode.light;
  bool _vibrateOnScan = true;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get vibrateOnScan => _vibrateOnScan;
  bool get isLoaded => _loaded;

  AppSettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_kTheme);
    switch (themeStr) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        // Default to light theme on first open
        _themeMode = ThemeMode.light;
    }
    _vibrateOnScan = prefs.getBool(_kVibrate) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final v = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_kTheme, v);
  }

  Future<void> setVibrateOnScan(bool value) async {
    _vibrateOnScan = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kVibrate, value);
  }
}
