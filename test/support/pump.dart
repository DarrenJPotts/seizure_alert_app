import 'package:flutter/material.dart';
import 'package:seizure_app/core/themes/app_theme.dart';

/// Host for a presentational widget that sizes itself.
///
/// Uses the real app theme rather than a bare MaterialApp so widgets reading
/// `Theme.of(context).textTheme` get the styles they get in the app — a null
/// textTheme entry renders differently and would hide a regression.
///
/// The scroll view keeps tall content from overflowing the 800x600 test
/// surface, which would otherwise fail the test for the wrong reason.
Widget wrap(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

/// Host for a widget that expects a bounded height — anything using Expanded
/// or Spacer, which a scroll view's unbounded constraints would break.
Widget wrapBounded(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(body: child),
);
