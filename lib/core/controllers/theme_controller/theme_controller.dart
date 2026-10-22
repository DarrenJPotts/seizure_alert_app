import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/shared_pref_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../themes/app_design.dart';

class ThemeController extends GetxService {
  ThemeController(
    this._prefs, {
    this.designSwitcherEnabled = designToolsAvailable,
  });

  static const bool designToolsAvailable =
      kDebugMode || bool.fromEnvironment('ENABLE_DESIGN_SWITCHER');

  final bool designSwitcherEnabled;

  late final Rx<AppDesignStyle> designStyle = Rx<AppDesignStyle>(_readDesign());

  AppDesignStyle get resolvedDesign =>
      designSwitcherEnabled ? designStyle.value : AppDesign.defaultStyle;

  AppDesignStyle _readDesign() {
    if (!designSwitcherEnabled) return AppDesign.defaultStyle;
    final stored = _prefs.getString(SharedPrefKeys.designStyle);
    return AppDesignStyle.values.firstWhere(
      (style) => style.name == stored,
      orElse: () => AppDesign.defaultStyle,
    );
  }

  Future<void> setDesignStyle(AppDesignStyle style) async {
    if (!designSwitcherEnabled || designStyle.value == style) return;
    designStyle.value = style;
    try {
      await _prefs.setString(SharedPrefKeys.designStyle, style.name);
    } catch (error) {
      debugPrint('[ThemeController] Could not persist design style: $error');
    }
  }

  static ThemeController instance() => Get.find<ThemeController>();

  static const bool darkModeAvailable = true;

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
