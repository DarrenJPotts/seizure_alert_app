import 'package:flutter/material.dart';

import 'colors/dark_colors.dart';
import 'colors/light_colors.dart';

abstract class AppColorSchemes {
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,

primary: Colors.black,
    onPrimary: Colors.white,
    primaryContainer: AppColorsLight.surfaceContainerHighest,
    onPrimaryContainer: Colors.black,
    primaryFixed: AppColorsLight.surfaceContainerHighest,
    primaryFixedDim: AppColorsLight.outlineVariant,
    onPrimaryFixed: Colors.black,
    onPrimaryFixedVariant: AppColorsLight.textSecondary,

secondary: AppColorsLight.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColorsLight.surfaceContainerHigh,
    onSecondaryContainer: Colors.black,
    secondaryFixed: AppColorsLight.surfaceContainerHigh,
    secondaryFixedDim: AppColorsLight.outlineVariant,
    onSecondaryFixed: Colors.black,
    onSecondaryFixedVariant: AppColorsLight.textSecondary,

    tertiary: AppColorsLight.secondary,
    onTertiary: Colors.white,
    tertiaryContainer: AppColorsLight.surfaceContainerHigh,
    onTertiaryContainer: Colors.black,
    tertiaryFixed: AppColorsLight.surfaceContainerHigh,
    tertiaryFixedDim: AppColorsLight.outlineVariant,
    onTertiaryFixed: Colors.black,
    onTertiaryFixedVariant: AppColorsLight.textSecondary,

error: AppColorsLight.accentRed,
    onError: Colors.white,
    errorContainer: AppColorsLight.errorContainer,
    onErrorContainer: AppColorsLight.onErrorContainer,

surface: AppColorsLight.surface,
    onSurface: Colors.black,
    onSurfaceVariant: AppColorsLight.textSecondary,
    surfaceDim: AppColorsLight.surfaceDim,
    surfaceBright: AppColorsLight.surfaceBright,
    surfaceContainerLowest: AppColorsLight.surfaceContainerLowest,
    surfaceContainerLow: AppColorsLight.surfaceContainerLow,
    surfaceContainer: AppColorsLight.surfaceContainer,
    surfaceContainerHigh: AppColorsLight.surfaceContainerHigh,
    surfaceContainerHighest: AppColorsLight.surfaceContainerHighest,

surfaceTint: Colors.transparent,

outline: AppColorsLight.outline,
    outlineVariant: AppColorsLight.outlineVariant,
    shadow: Colors.black,
    scrim: Colors.black,

inverseSurface: Colors.black,
    onInverseSurface: Colors.white,
    inversePrimary: Colors.white,
  );

static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,

primary: Colors.white,
    onPrimary: Colors.black,
    primaryContainer: AppColorsDark.surfaceContainerHighest,
    onPrimaryContainer: Colors.white,
    primaryFixed: AppColorsDark.surfaceContainerHighest,
    primaryFixedDim: AppColorsDark.outlineVariant,
    onPrimaryFixed: Colors.white,
    onPrimaryFixedVariant: AppColorsDark.textSecondary,

secondary: AppColorsDark.secondary,
    onSecondary: Colors.black,
    secondaryContainer: AppColorsDark.surfaceContainerHigh,
    onSecondaryContainer: Colors.white,
    secondaryFixed: AppColorsDark.surfaceContainerHigh,
    secondaryFixedDim: AppColorsDark.outlineVariant,
    onSecondaryFixed: Colors.white,
    onSecondaryFixedVariant: AppColorsDark.textSecondary,

    tertiary: AppColorsDark.secondary,
    onTertiary: Colors.black,
    tertiaryContainer: AppColorsDark.surfaceContainerHigh,
    onTertiaryContainer: Colors.white,
    tertiaryFixed: AppColorsDark.surfaceContainerHigh,
    tertiaryFixedDim: AppColorsDark.outlineVariant,
    onTertiaryFixed: Colors.white,
    onTertiaryFixedVariant: AppColorsDark.textSecondary,

error: AppColorsDark.accentRed,
    onError: Colors.black,
    errorContainer: AppColorsDark.errorContainer,
    onErrorContainer: AppColorsDark.onErrorContainer,

surface: AppColorsDark.background,
    onSurface: Colors.white,
    onSurfaceVariant: AppColorsDark.textSecondary,
    surfaceDim: AppColorsDark.surfaceDim,
    surfaceBright: AppColorsDark.surfaceBright,
    surfaceContainerLowest: AppColorsDark.surfaceContainerLowest,
    surfaceContainerLow: AppColorsDark.surfaceContainerLow,
    surfaceContainer: AppColorsDark.surfaceContainer,
    surfaceContainerHigh: AppColorsDark.surfaceContainerHigh,
    surfaceContainerHighest: AppColorsDark.surfaceContainerHighest,

surfaceTint: Colors.transparent,

outline: AppColorsDark.outline,
    outlineVariant: AppColorsDark.outlineVariant,
    shadow: Colors.black,
    scrim: Colors.black,

inverseSurface: Colors.white,
    onInverseSurface: Colors.black,
    inversePrimary: Colors.black,
  );
}
