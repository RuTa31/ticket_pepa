import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_client.dart';
import '../../services/device_id.dart';

class AuthProvider extends ChangeNotifier {
  static const _keyLoggedIn = 'auth_logged_in_v1';
  static const _keyToken = 'auth_token_v1';
  static const _keyRole = 'auth_role_v1';
  static const _keyProfile = 'auth_profile_v1';

  bool _loaded = false;
  bool _loggedIn = false;
  String? _token;
  UserProfile? _profile;
  String? _lastError;

  bool get isLoaded => _loaded;
  bool get isLoggedIn => _loggedIn;
  String? get token => _token;
  UserProfile? get profile => _profile;
  String? get email => _profile?.email;
  String? get lastError => _lastError;

  final ApiClient _api = ApiClient();

  AuthProvider() {
    _load();
  }

  Future<void> _load() async {
    print('🔄 AuthProvider: Loading saved session...');
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    _token = prefs.getString(_keyToken);
    prefs.getString(_keyRole);
    final profileJson = prefs.getString(_keyProfile);

    print('   Logged in: $_loggedIn');
    print('   Token exists: ${_token != null}');
    print('   Profile exists: ${profileJson != null}');

    if (_loggedIn && _token != null && profileJson != null) {
      try {
        final map = json.decode(profileJson) as Map<String, dynamic>;
        _profile = UserProfile.fromJson(map);
        print('   Username: ${_profile?.username}');
        print('   Role: ${_profile?.role.name}');
      } catch (e) {
        print('   ⚠️ Failed to parse profile: $e');
        _loggedIn = false;
        _token = null;
        _profile = null;
      }
    }
    _loaded = true;
    print('✅ AuthProvider: Load complete');
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) return false;
    try {
      _lastError = null;
      final deviceName = await DeviceId.getId();

      print('📱 AuthProvider: Starting login...');
      print('   Username: $username');
      print('   Device: $deviceName');

      final result = await _api.loginUnified(
        username: username.trim(),
        password: password,
        deviceName: deviceName,
      );

      print('💾 AuthProvider: Saving to SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLoggedIn, true);
      await prefs.setString(_keyToken, result.token);
      await prefs.setString(_keyRole, result.profile.role.name);
      await prefs.setString(_keyProfile, json.encode(result.profile.toJson()));

      _loggedIn = true;
      _token = result.token;
      _profile = result.profile;
      _lastError = null;

      print('✅ AuthProvider: Login successful!');
      print('   Logged in: $_loggedIn');
      print('   Token: ${_token?.substring(0, 20)}...');
      print('   Username: ${_profile?.username}');
      print('   Role: ${_profile?.role.name}');
      print('   Profile JSON: ${json.encode(_profile?.toJson())}');

      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString().replaceFirst('Exception: ', '');
      print('❌ AuthProvider: Login failed!');
      print('   Error: $_lastError');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    print('🚪 AuthProvider: Logging out...');
    print('   Current logged in: $_loggedIn');
    print('   Current username: ${_profile?.username}');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyProfile);

    print('   Removed from SharedPreferences');

    _loggedIn = false;
    _token = null;
    _profile = null;

    print('✅ AuthProvider: Logout complete');
    print('   Logged in: $_loggedIn');
    print('   Token: ${_token}');
    print('   Profile: ${_profile}');

    notifyListeners();
  }
}
