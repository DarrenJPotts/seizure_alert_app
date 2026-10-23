import 'package:flutter/material.dart';
import '../constants/dimensions.dart';

enum AppDesignStyle { softEditorial }

/// Visual choices only. No alert timing, interaction or medical state belongs here.
@immutable
class AppDesign extends ThemeExtension<AppDesign> {
  const AppDesign(this.style);

  static const defaultStyle = AppDesignStyle.softEditorial;
  final AppDesignStyle style;

  bool get raisedSurfaces => true;
  Color pageSurface(ColorScheme scheme) => scheme.brightness == Brightness.light
      ? const Color(0xFFF3F3F3)
      : const Color(0xFF161616);
  Color panelSurface(ColorScheme scheme) =>
      scheme.brightness == Brightness.light
      ? Colors.white
      : const Color(0xFF252525);
  List<BoxShadow> shadows(Brightness brightness) => [
    BoxShadow(
      color: Colors.black.withValues(
        alpha: brightness == Brightness.light ? 0.07 : 0.18,
      ),
      blurRadius: Dimensions.twentyFour,
      offset: const Offset(0, Dimensions.eight),
    ),
  ];
  double get cardRadius => Dimensions.twentyFour;
  double get featureRadius => Dimensions.thirtyTwo;
  double get navRadius => Dimensions.twentyEight;
  double get borderWidth => 1;
  double get borderOpacity => 0.04;
  bool get filledCards => false;
  bool get filledSelection => true;
  bool get heroDivider => false;
  double get cardPadding => Dimensions.twenty;
  double get sectionGap => Dimensions.thirtyTwo;
  double get heroGap => Dimensions.sixteen;
  double get heroSize => 64;

  TextTheme applyTypography(TextTheme base) {
    TextStyle? heading(TextStyle? source, {double? size}) => source?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: size,
      letterSpacing: 0,
    );
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontSize: heroSize),
      headlineLarge: heading(base.headlineLarge, size: 34),
      headlineMedium: heading(base.headlineMedium),
      headlineSmall: heading(base.headlineSmall),
      titleLarge: heading(base.titleLarge),
      titleMedium: heading(base.titleMedium),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  TextStyle? greetingStyle(TextTheme theme) => theme.headlineMedium;

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
