import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'colors/dark_colors.dart';
import 'colors/light_colors.dart';

class AppColors {
  // Helper to check if dark mode
  static bool get _isDark => Get.isDarkMode;

  // Primary Colors
  static Color get primary => _isDark ? AppColorsDark.primary : AppColorsLight.primary;

  static Color get primaryLight => _isDark ? AppColorsDark.primaryLight : AppColorsLight.primaryLight;

  static Color get primaryDark => _isDark ? AppColorsDark.primaryDark : AppColorsLight.primaryDark;

  // Secondary Colors
  static Color get secondary => _isDark ? AppColorsDark.secondary : AppColorsLight.secondary;

  static Color get secondaryLight => _isDark ? AppColorsDark.secondaryLight : AppColorsLight.secondaryLight;

  static Color get secondaryDark => _isDark ? AppColorsDark.secondaryDark : AppColorsLight.secondaryDark;

  // Background Colors
  static Color get background => _isDark ? AppColorsDark.background : AppColorsLight.background;

  static Color get surface => _isDark ? AppColorsDark.surface : AppColorsLight.surface;

  static Color get cardBackground => _isDark ? AppColorsDark.cardBackground : AppColorsLight.cardBackground;

  // Text Colors
  static Color get textPrimary => _isDark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;

  static Color get textSecondary => _isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;

  static Color get textDisabled => _isDark ? AppColorsDark.textDisabled : AppColorsLight.textDisabled;

  static Color get textHint => _isDark ? AppColorsDark.textHint : AppColorsLight.textHint;

  // Accent Colors
  static Color get accent => _isDark ? AppColorsDark.accent : AppColorsLight.accent;

  static Color get error => _isDark ? AppColorsDark.accentRed : AppColorsLight.accentRed;

  static Color get success => _isDark ? AppColorsDark.accentGreen : AppColorsLight.accentGreen;

  static Color get warning => _isDark ? AppColorsDark.accentOrange : AppColorsLight.accentOrange;

  // Aliases for accent colors
  static Color get accentRed => error;

  static Color get accentGreen => success;

  static Color get accentOrange => warning;

  // UI Elements
  static Color get divider => _isDark ? AppColorsDark.divider : AppColorsLight.divider;

  static Color get border => _isDark ? AppColorsDark.border : AppColorsLight.border;

  static Color get shadow => _isDark ? AppColorsDark.shadow : AppColorsLight.shadow;

  static Color get overlay => _isDark ? AppColorsDark.overlay : AppColorsLight.overlay;

  // Progress/Indicators
  static Color get progressActive => _isDark ? AppColorsDark.progressActive : AppColorsLight.progressActive;

  static Color get progressInactive => _isDark ? AppColorsDark.progressInactive : AppColorsLight.progressInactive;

  // Floating Action Button
  static Color get fabBackground => _isDark ? AppColorsDark.fabBackground : AppColorsLight.fabBackground;

  static Color get fabIcon => _isDark ? AppColorsDark.fabIcon : AppColorsLight.fabIcon;
}
