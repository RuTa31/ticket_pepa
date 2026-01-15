import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class AppColors {
  static Color primaryColor = const Color(0xFF000000);
  static const Color secondaryColor = Color(0xffffffff);

  static final ValueNotifier<int> _themeVersion = ValueNotifier<int>(0);
  static ValueListenable<int> get themeVersion => _themeVersion;

  static void applyBrand({required Color primary}) {
    primaryColor = primary;
    try {
      _themeVersion.value++;
    } catch (_) {}
  }
}
