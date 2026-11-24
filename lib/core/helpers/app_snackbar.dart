import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/constants/snackbar_margin.dart';

/// A short message at the bottom of the screen, readable in both themes.
///
/// `Get.snackbar` with no colours draws black text on a translucent grey
/// panel. On the black caregiver alert screen and anywhere in dark mode that
/// text was close to invisible, including "Could not respond" when a
/// caregiver's response failed. This uses the theme's inverse surface, the
/// same pair Material uses for its own snackbars.
void showAppSnackbar(
  String title,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  final ColorScheme scheme = Get.theme.colorScheme;

  Get.snackbar(
    '',
    '',
    titleText: Text(
      title,
      style: TextStyle(
        color: scheme.onInverseSurface,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
    messageText: Text(
      message,
      style: TextStyle(color: scheme.onInverseSurface),
    ),
    snackPosition: SnackPosition.BOTTOM,
    margin: snackbarMargin,
    backgroundColor: scheme.inverseSurface,
    borderRadius: Dimensions.eight,
    duration: duration,
  );
}
