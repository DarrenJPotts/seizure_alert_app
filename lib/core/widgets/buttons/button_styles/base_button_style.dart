import 'package:flutter/material.dart';
import 'package:seizure_app/core/widgets/buttons/button_styles/secondary_outline_button_style.dart';
import 'package:seizure_app/core/widgets/buttons/button_styles/secondary_text_button_style.dart';

import 'primary_button_style.dart';
import 'secondary_button_style.dart';

/// `BaseButtonStyle` is the base class for all button styles.
/// It provides a common structure and properties that can be extended by specific button styles.
/// It should be used as followed:
/// ```dart
/// BaseButtonStyle.primaryButton(context: context);
/// BaseButtonStyle.outlineButton(context: context);
/// BaseButtonStyle.secondaryButton(context: context);
/// ```
class BaseButtonStyle {
  const BaseButtonStyle({
    required this.buttonColor,
    required this.textColor,
    required this.borderColor,
    required this.loaderColor,
    required this.loaderBackgroundColor,
    required this.disabledColor,
    required this.textStyle,
    required this.disabledTextStyle,
    required this.borderRadius,
    required this.padding,
    required this.borderWidth,
    required this.loaderWidth,
    required this.loaderHeight,
    required this.textAlign,
    required this.maxLines,
    required this.textOverflow,
    required this.disabledLoaderColor,
    required this.disabledLoaderBackgroundColor,
    required this.disabledBorderColor,
    required this.hoverColor,
    required this.disabledHoverColor,
    required this.borderHoverWidth,
  });

  /// `Style Factories`
  /// These factories create instances of specific button styles based on the context provided.
  /// They should be used as follows:
  /// ```dart
  /// BaseButtonStyle.primaryButton(context: context);
  /// BaseButtonStyle.secondaryButton(context: context);
  /// ```
  factory BaseButtonStyle.primaryButton({required BuildContext context}) => PrimaryButtonStyle(context: context);

  factory BaseButtonStyle.secondaryButton({required BuildContext context}) => SecondaryButtonStyle(context: context);

  factory BaseButtonStyle.secondaryOutlineButtonStyle({required BuildContext context}) => SecondaryOutlineButtonStyle(context: context);
  factory BaseButtonStyle.secondaryTextButtonStyle({required BuildContext context}) => SecondaryTextButtonStyle(context: context);

  /// `Colors - Enabled`
  final Color buttonColor;
  final Color textColor;
  final Color borderColor;
  final Color loaderColor;
  final Color loaderBackgroundColor;
  final Color hoverColor;

  /// `Colors - Disabled`
  final Color disabledBorderColor;
  final Color disabledColor;
  final Color disabledLoaderColor;
  final Color disabledLoaderBackgroundColor;
  final Color disabledHoverColor;

  /// `TextStyle`
  final TextStyle textStyle;
  final TextStyle disabledTextStyle;

  /// `Decoration`
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final double borderHoverWidth;
  final double loaderWidth;
  final double loaderHeight;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow textOverflow;

  /// `Copy with`
  /// This method allows you to create a copy of the current style with some properties modified.
  /// It should be used as follows:
  /// ```dart
  /// BaseButtonStyle modifiedButtonStyle = baseButtonStyle.primary(context: context).copyWith(
  ///   buttonColor: Colors.red,
  ///   textColor: Colors.white,
  /// );
  /// ```
  BaseButtonStyle copyWith({
    Color? buttonColor,
    Color? textColor,
    Color? borderColor,
    Color? loaderColor,
    Color? loaderBackgroundColor,
    Color? disabledColor,
    TextStyle? textStyle,
    TextStyle? disabledTextStyle,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    double? borderWidth,
    double? loaderWidth,
    double? loaderHeight,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? textOverflow,
    Color? disabledLoaderColor,
    Color? disabledLoaderBackgroundColor,
    Color? disabledBorderColor,
    Color? hoverColor,
    Color? disabledHoverColor,
    double? borderHoverWidth,
  }) => BaseButtonStyle(
    buttonColor: buttonColor ?? this.buttonColor,
    textColor: textColor ?? this.textColor,
    borderColor: borderColor ?? this.borderColor,
    loaderColor: loaderColor ?? this.loaderColor,
    loaderBackgroundColor: loaderBackgroundColor ?? this.loaderBackgroundColor,
    disabledColor: disabledColor ?? this.disabledColor,
    textStyle:
        textStyle?.copyWith(color: textColor ?? this.textColor) ??
        this.textStyle.copyWith(color: textColor ?? this.textColor),
    disabledTextStyle: disabledTextStyle ?? this.disabledTextStyle,
    borderRadius: borderRadius ?? this.borderRadius,
    padding: padding ?? this.padding,
    borderWidth: borderWidth ?? this.borderWidth,
    loaderWidth: loaderWidth ?? this.loaderWidth,
    loaderHeight: loaderHeight ?? this.loaderHeight,
    textAlign: textAlign ?? this.textAlign,
    maxLines: maxLines ?? this.maxLines,
    textOverflow: textOverflow ?? this.textOverflow,
    disabledLoaderColor: disabledLoaderColor ?? this.disabledLoaderColor,
    disabledLoaderBackgroundColor: disabledLoaderBackgroundColor ?? this.disabledLoaderBackgroundColor,
    disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
    hoverColor: hoverColor ?? this.hoverColor,
    disabledHoverColor: disabledHoverColor ?? this.disabledHoverColor,
    borderHoverWidth: borderHoverWidth ?? this.borderHoverWidth,
  );
}
