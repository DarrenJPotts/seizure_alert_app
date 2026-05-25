import 'package:flutter/material.dart';
import 'colors/light_colors.dart';

abstract class AppTheme {
  static const String fontFamily = 'RedHatDisplay';

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColorsLight.primary,
      secondary: AppColorsLight.secondary,
      surface: AppColorsLight.background,
      error: AppColorsLight.accentRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColorsLight.textPrimary,
      onError: Colors.white,
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily, fontSize: 96, fontWeight: FontWeight.w300, color: AppColorsLight.textPrimary),
      displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 60, fontWeight: FontWeight.w300, color: AppColorsLight.textPrimary),
      displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 48, fontWeight: FontWeight.w400, color: AppColorsLight.textPrimary),
      headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 34, fontWeight: FontWeight.w600, color: AppColorsLight.textPrimary),
      headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w600, color: AppColorsLight.textPrimary),
      headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w500, color: AppColorsLight.textPrimary),
      titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w500, color: AppColorsLight.textPrimary),
      titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: AppColorsLight.textPrimary),
      titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: AppColorsLight.textPrimary),
      bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: AppColorsLight.textPrimary),
      bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: AppColorsLight.textPrimary),
      bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: AppColorsLight.textSecondary),
      labelLarge: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: AppColorsLight.textPrimary),
      labelMedium: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: AppColorsLight.textSecondary),
      labelSmall: TextStyle(fontFamily: fontFamily, fontSize: 10, fontWeight: FontWeight.w400, color: AppColorsLight.textSecondary),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(color: AppColorsLight.divider, thickness: 1, space: 1),
    scaffoldBackgroundColor: AppColorsLight.background,
  );
}
