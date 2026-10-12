import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/shared_pref_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxService {
  ThemeController(this._prefs);

  static ThemeController instance() => Get.find<ThemeController>();

  static const bool darkModeAvailable = false;

  static const ThemeMode defaultMode = ThemeMode.system;

  final SharedPreferences _prefs;

  late final Rx<ThemeMode> themeMode = Rx<ThemeMode>(_read());

  Future<ThemeController> init() async => this;

  ThemeMode get resolvedMode {
    final ThemeMode preferred = themeMode.value;
    return darkModeAvailable ? preferred : ThemeMode.light;
  }

  bool get prefersDark => themeMode.value == ThemeMode.dark;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode.value == mode) return;
    themeMode.value = mode;
    await _write(mode);
  }

  Future<void> setDarkMode(bool enabled) =>
      setThemeMode(enabled ? ThemeMode.dark : defaultMode);

  ThemeMode _read() {
    final String? stored = _prefs.getString(SharedPrefKeys.themeMode);
    if (stored == null) return defaultMode;

    for (final ThemeMode mode in ThemeMode.values) {
      if (mode.name == stored) return mode;
    }
    debugPrint('[ThemeController] Unrecognised stored theme mode: $stored');
    return defaultMode;
  }

  Future<void> _write(ThemeMode mode) async {
    try {
      await _prefs.setString(SharedPrefKeys.themeMode, mode.name);
    } catch (e) {
      debugPrint('[ThemeController] Could not persist theme mode: $e');
    }
  }
}
