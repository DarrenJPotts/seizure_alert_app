import 'package:flutter/material.dart';
import '../constants/dimensions.dart';

enum AppDesignStyle {
  clinical('Clinical', 'Quiet typography, subtle borders, familiar spacing.'),
  bold('Bold', 'Heavy headings, strong outlines, oversized summaries.'),
  swiss('Swiss', 'Precise alignment, compact corners, confident typography.'),
  soft('Soft minimal', 'Rounded surfaces, gentle fills, generous spacing.'),
  editorial('Editorial', 'Large headings, fine rules, open composition.'),
  softEditorial(
    'Soft editorial',
    'White rounded cards, gentle shadows, charcoal controls.',
  ),
  instrument(
    'Instrument panel',
    'Compact panels, clear outlines, aligned data.',
  );

  const AppDesignStyle(this.label, this.description);
  final String label;
  final String description;
}

/// Visual choices only. No alert timing, interaction or medical state belongs here.
@immutable
class AppDesign extends ThemeExtension<AppDesign> {
  const AppDesign(this.style);

  static const defaultStyle = AppDesignStyle.softEditorial;
  final AppDesignStyle style;

  bool get raisedSurfaces => style == AppDesignStyle.softEditorial;

  Color pageSurface(ColorScheme scheme) => raisedSurfaces
      ? (scheme.brightness == Brightness.light
            ? const Color(0xFFF3F3F3)
            : const Color(0xFF161616))
      : scheme.surface;

  Color panelSurface(ColorScheme scheme) => raisedSurfaces
      ? (scheme.brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF252525))
      : filledCards
      ? scheme.surfaceContainerLow
      : scheme.surface;

  List<BoxShadow> shadows(Brightness brightness) => raisedSurfaces
      ? [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: brightness == Brightness.light ? 0.07 : 0.18,
            ),
            blurRadius: Dimensions.twentyFour,
            offset: const Offset(0, Dimensions.eight),
          ),
        ]
      : const [];

  double get cardRadius => switch (style) {
    AppDesignStyle.swiss => Dimensions.eight,
    AppDesignStyle.soft => Dimensions.twenty,
    AppDesignStyle.softEditorial => Dimensions.twentyFour,
    AppDesignStyle.editorial => Dimensions.four,
    AppDesignStyle.instrument => Dimensions.eight,
    _ => Dimensions.twelve,
  };

  double get featureRadius => switch (style) {
    AppDesignStyle.soft => Dimensions.twentyFour,
    AppDesignStyle.softEditorial => Dimensions.thirtyTwo,
    AppDesignStyle.clinical || AppDesignStyle.bold => Dimensions.sixteen,
    _ => cardRadius,
  };

  double get navRadius => switch (style) {
    AppDesignStyle.softEditorial => Dimensions.twentyEight,
    AppDesignStyle.clinical || AppDesignStyle.bold || AppDesignStyle.soft => 35,
    _ => cardRadius,
  };

  double get borderWidth => style == AppDesignStyle.bold ? 2 : 1;
  double get borderOpacity => switch (style) {
    AppDesignStyle.bold => 1,
    AppDesignStyle.swiss || AppDesignStyle.instrument => 0.35,
    AppDesignStyle.editorial => 0.2,
    AppDesignStyle.soft => 0.08,
    AppDesignStyle.softEditorial => 0.04,
    AppDesignStyle.clinical => 0.12,
  };

  bool get filledCards => style == AppDesignStyle.soft;
  bool get filledSelection => switch (style) {
    AppDesignStyle.bold ||
    AppDesignStyle.soft ||
    AppDesignStyle.softEditorial ||
    AppDesignStyle.instrument => true,
    _ => false,
  };

  bool get heroDivider =>
      style != AppDesignStyle.clinical &&
      style != AppDesignStyle.soft &&
      !raisedSurfaces;
  double get cardPadding => style == AppDesignStyle.soft || raisedSurfaces
      ? Dimensions.twenty
      : Dimensions.sixteen;
  double get sectionGap => switch (style) {
    AppDesignStyle.soft ||
    AppDesignStyle.editorial ||
    AppDesignStyle.softEditorial => Dimensions.thirtyTwo,
    AppDesignStyle.instrument => Dimensions.sixteen,
    _ => Dimensions.twentyFour,
  };
  double get heroGap =>
      style == AppDesignStyle.clinical ? Dimensions.eight : Dimensions.sixteen;
  double get heroSize => switch (style) {
    AppDesignStyle.clinical => 56,
    AppDesignStyle.bold => 96,
    AppDesignStyle.swiss => 80,
    AppDesignStyle.soft => 64,
    AppDesignStyle.softEditorial => 64,
    AppDesignStyle.editorial => 88,
    AppDesignStyle.instrument => 60,
  };

  TextTheme applyTypography(TextTheme base) {
    final headingWeight = switch (style) {
      AppDesignStyle.clinical ||
      AppDesignStyle.soft ||
      AppDesignStyle.softEditorial => FontWeight.w600,
      _ => FontWeight.w700,
    };
    final tracking = switch (style) {
      AppDesignStyle.bold => -0.8,
      AppDesignStyle.swiss => -1.0,
      AppDesignStyle.editorial => -1.2,
      _ => 0.0,
    };
    TextStyle? heading(TextStyle? source, {double? size}) => source?.copyWith(
      fontWeight: headingWeight,
      fontSize: size,
      letterSpacing: tracking,
    );
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: heroSize,
        fontFeatures: style == AppDesignStyle.instrument
            ? const [FontFeature.tabularFigures()]
            : null,
      ),
      headlineLarge: heading(
        base.headlineLarge,
        size: style == AppDesignStyle.editorial ? 40 : 34,
      ),
      headlineMedium: heading(base.headlineMedium),
      headlineSmall: heading(base.headlineSmall),
      titleLarge: heading(base.titleLarge),
      titleMedium: heading(base.titleMedium),
      labelLarge: base.labelLarge?.copyWith(fontWeight: headingWeight),
    );
  }

  TextStyle? greetingStyle(TextTheme theme) => switch (style) {
    AppDesignStyle.clinical => theme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    AppDesignStyle.soft ||
    AppDesignStyle.instrument ||
    AppDesignStyle.softEditorial => theme.headlineMedium,
    _ => theme.headlineLarge,
  };

  @override
  AppDesign copyWith({AppDesignStyle? style}) => AppDesign(style ?? this.style);

  @override
  AppDesign lerp(covariant AppDesign? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension DesignContext on BuildContext {
  AppDesign get design =>
      Theme.of(this).extension<AppDesign>() ??
      const AppDesign(AppDesign.defaultStyle);

  Border get designBorder => Border.all(
    color: Theme.of(
      this,
    ).colorScheme.onSurface.withValues(alpha: design.borderOpacity),
    width: design.borderWidth,
  );

  Color get cardSurface => design.panelSurface(Theme.of(this).colorScheme);

  List<BoxShadow> get designShadows =>
      design.shadows(Theme.of(this).brightness);
}
