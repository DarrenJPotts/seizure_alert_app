import 'package:flutter/material.dart';
import 'app_design.dart';

export 'app_design.dart';

/// Monochrome roles for custom widgets, resolved from their inherited theme.
extension AppPalette on BuildContext {
  Color get heroSurface => design.raisedSurfaces
      ? const Color(0xFF303030)
      : Theme.of(this).brightness == Brightness.dark
      ? Theme.of(this).colorScheme.surfaceContainerHigh
      : Colors.black;
  Color get heroInk => Colors.white;
  Color get secondaryInk => MediaQuery.highContrastOf(this)
      ? ink
      : Theme.of(this).brightness == Brightness.dark
      ? const Color(0xFFB0B0B0)
      : const Color(0xFF595959);
  Color get ink => Theme.of(this).colorScheme.onSurface;
  Color get paper => design.raisedSurfaces
      ? cardSurface
      : Theme.of(this).brightness == Brightness.dark
      ? Theme.of(this).colorScheme.surfaceContainerHigh
      : Theme.of(this).colorScheme.surface;
}
