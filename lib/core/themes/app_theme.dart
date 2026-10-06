import 'package:flutter/material.dart';

import '../constants/dimensions.dart';
import 'color_schemes.dart';
import 'colors/dark_colors.dart';
import 'colors/light_colors.dart';

abstract class AppTheme {
  static const String fontFamily = 'RedHatDisplay';

static const double radiusStandard = 12;

static const double radiusOutlinedButton = 10;

static const double radiusFeature = 16;

static const double radiusSheet = 24;

static const double _disabledOpacity = 0x61 / 255;

  static final ThemeData lightTheme = _build(
    AppColorSchemes.light,
    _textTheme(
      primary: AppColorsLight.textPrimary,
      secondary: AppColorsLight.textSecondary,
    ),
  );

  static final ThemeData darkTheme = _build(
    AppColorSchemes.dark,
    _textTheme(
      primary: AppColorsDark.textPrimary,
      secondary: AppColorsDark.textSecondary,
    ),
  );

  static ThemeData _build(ColorScheme colorScheme, TextTheme textTheme) {
    final Color disabled =
        colorScheme.onSurface.withValues(alpha: _disabledOpacity);

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: colorScheme.surface,
      iconTheme: IconThemeData(color: colorScheme.onSurface),

appBarTheme: AppBarThemeData(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFeature),
        ),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: colorScheme.outlineVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusSheet),
          ),
        ),
      ),

elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: disabled,
          disabledForegroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: Dimensions.sixteen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusStandard),
          ),
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(64, 48),
        ),
      ),

filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: disabled,
          disabledForegroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: Dimensions.sixteen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusStandard),
          ),
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(64, 48),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: disabled,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusOutlinedButton),
          ),
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(64, 48),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: disabled,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(64, 48),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: disabled,
          minimumSize: const Size(48, 48),
        ),
      ),

inputDecorationTheme: InputDecorationThemeData(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Dimensions.sixteen,
          vertical: Dimensions.fourteen,
        ),
        border: _inputBorder(colorScheme.outlineVariant),
        enabledBorder: _inputBorder(colorScheme.outlineVariant),
        disabledBorder: _inputBorder(colorScheme.outlineVariant),
        focusedBorder: _inputBorder(colorScheme.onSurface, width: 1.5),
        errorBorder: _inputBorder(colorScheme.error, width: 1.5),
        focusedErrorBorder: _inputBorder(colorScheme.error, width: 1.5),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.onSurface,
        selectionHandleColor: colorScheme.onSurface,
        selectionColor: colorScheme.onSurface.withValues(alpha: 0.18),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return states.contains(WidgetState.selected)
                ? colorScheme.onSurface.withValues(alpha: 0.26)
                : Colors.transparent;
          }
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : Colors.transparent;
        }),
        checkColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.disabled)
              ? colorScheme.surface
              : colorScheme.onPrimary,
        ),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.four),
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.26);
          }
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.outline;
        }),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.26);
          }
          return states.contains(WidgetState.selected)
              ? colorScheme.onPrimary
              : colorScheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.12);
          }
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStatePropertyAll<Color>(colorScheme.outline),
      ),

snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.onInverseSurface,

behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.onSurface,
        linearTrackColor: colorScheme.outlineVariant,
        circularTrackColor: Colors.transparent,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(Dimensions.eight),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.bodyMedium,
        subtitleTextStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusStandard),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusStandard),
        borderSide: BorderSide(color: color, width: width),
      );

static TextTheme _textTheme({
    required Color primary,
    required Color secondary,
  }) => TextTheme(
    displayLarge: TextStyle(fontFamily: fontFamily, fontSize: 96, fontWeight: FontWeight.w300, color: primary),
    displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 60, fontWeight: FontWeight.w300, color: primary),
    displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 48, fontWeight: FontWeight.w400, color: primary),
    headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 34, fontWeight: FontWeight.w600, color: primary),
    headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w600, color: primary),
    headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w500, color: primary),
    titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w500, color: primary),
    titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: primary),
    titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: primary),
    bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: primary),
    bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: primary),
    bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
    labelLarge: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: primary),
    labelMedium: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
    labelSmall: TextStyle(fontFamily: fontFamily, fontSize: 10, fontWeight: FontWeight.w400, color: secondary),
  );
}
