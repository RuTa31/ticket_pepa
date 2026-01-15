import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../common/app_colors.dart';
import 'api_client.dart';

class BasicService {
  BasicService._();

  // Only keep: logo, favicon, mobile primary color
  static final ValueNotifier<int> brandingVersion = ValueNotifier<int>(0);

  static const _kLogoBytes = 'branding_logo_bytes_v1';
  static const _kFavBytes = 'branding_fav_bytes_v1';
  static const _kLogoUrl = 'branding_logo_url_v1';
  static const _kFavUrl = 'branding_fav_url_v1';
  static const _kPrimaryHex = 'branding_primary_hex_v1';

  static Uint8List? _logoBytesMem;
  static Uint8List? _favBytesMem;
  static String? _logoUrlMem;
  static String? _favUrlMem;
  static String? _primaryHexMem;
  static DateTime? _lastFetch;

  static const _ttl = Duration(minutes: 30);

  static Color _parseHexColor(String hex) {
    var s = hex.trim().replaceAll('#', '');
    if (s.length == 6) s = 'FF$s';
    final val = int.tryParse(s, radix: 16) ?? 0xFF000000;
    return Color(val);
  }

  static Future<void> ensureBrandingCached({bool force = false}) async {
    try {
      final now = DateTime.now();
      if (!force && _lastFetch != null && now.difference(_lastFetch!) < _ttl) {
        // Apply cached color if available
        final hex =
            _primaryHexMem ?? (await _getPrefs()).getString(_kPrimaryHex);
        if (hex != null && hex.isNotEmpty) {
          AppColors.applyBrand(primary: _parseHexColor(hex));
        }
        return;
      }

      // Load persisted into memory first
      final prefs = await _getPrefs();
      _logoUrlMem ??= prefs.getString(_kLogoUrl);
      _favUrlMem ??= prefs.getString(_kFavUrl);
      _primaryHexMem ??= prefs.getString(_kPrimaryHex);
      final bLogo = prefs.getString(_kLogoBytes);
      if (bLogo != null && _logoBytesMem == null) {
        try {
          _logoBytesMem = base64Decode(bLogo);
        } catch (_) {}
      }
      final bFav = prefs.getString(_kFavBytes);
      if (bFav != null && _favBytesMem == null) {
        try {
          _favBytesMem = base64Decode(bFav);
        } catch (_) {}
      }
      if (_primaryHexMem != null) {
        AppColors.applyBrand(primary: _parseHexColor(_primaryHexMem!));
      }

      // Fetch remote basic
      final base = apiBaseUrl.replaceAll(RegExp(r"/+$"), '');
      final uri = Uri.parse('$base/api/scanner/get-basic');
      final res = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      if (res.statusCode != 200) return;
      final Map<String, dynamic> decoded = json.decode(res.body);
      final Map<String, dynamic>? basic =
          (decoded['data']?['basic_data'] as Map?)?.cast<String, dynamic>();
      if (basic == null) return;

      final logoUrl = basic['mobile_app_logo']?.toString();
      final favUrl = basic['mobile_favicon']?.toString();
      final primaryHex = basic['mobile_primary_colour']?.toString();

      // Download images if URLs present
      if (logoUrl != null && logoUrl.isNotEmpty) {
        try {
          final img = await http.get(Uri.parse(logoUrl));
          if (img.statusCode == 200 && img.bodyBytes.isNotEmpty) {
            _logoBytesMem = img.bodyBytes;
            await prefs.setString(_kLogoBytes, base64Encode(_logoBytesMem!));
            await prefs.setString(_kLogoUrl, logoUrl);
            _logoUrlMem = logoUrl;
          }
        } catch (_) {}
      }

      if (favUrl != null && favUrl.isNotEmpty) {
        try {
          final img = await http.get(Uri.parse(favUrl));
          if (img.statusCode == 200 && img.bodyBytes.isNotEmpty) {
            _favBytesMem = img.bodyBytes;
            await prefs.setString(_kFavBytes, base64Encode(_favBytesMem!));
            await prefs.setString(_kFavUrl, favUrl);
            _favUrlMem = favUrl;
          }
        } catch (_) {}
      }

      if (primaryHex != null && primaryHex.isNotEmpty) {
        _primaryHexMem = primaryHex;
        await prefs.setString(_kPrimaryHex, primaryHex);
        AppColors.applyBrand(primary: _parseHexColor(primaryHex));
      }

      _lastFetch = now;
      try {
        brandingVersion.value++;
      } catch (_) {}
    } catch (_) {
      // ignore
    }
  }

  static Future<SharedPreferences> _getPrefs() =>
      SharedPreferences.getInstance();

  static Future<Uint8List?> getCachedBrandingBytes(String type) async {
    final prefs = await _getPrefs();
    if (type == 'favicon') {
      if (_favBytesMem != null && _favBytesMem!.isNotEmpty) return _favBytesMem;
      final s = prefs.getString(_kFavBytes);
      if (s != null) {
        try {
          return _favBytesMem = base64Decode(s);
        } catch (_) {}
      }
    } else {
      if (_logoBytesMem != null && _logoBytesMem!.isNotEmpty) {
        return _logoBytesMem;
      }
      final s = prefs.getString(_kLogoBytes);
      if (s != null) {
        try {
          return _logoBytesMem = base64Decode(s);
        } catch (_) {}
      }
    }
    return null;
  }

  static Future<String?> getCachedPrimaryColorHex() async {
    if (_primaryHexMem != null) return _primaryHexMem;
    final prefs = await _getPrefs();
    return prefs.getString(_kPrimaryHex);
  }
}
