import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';

import 'base_button_style.dart';

final class SecondaryTextButtonStyle extends BaseButtonStyle {
  SecondaryTextButtonStyle({required this.context})
    : super(
        buttonColor: Colors.transparent,
        textColor: context.secondaryInk,
        borderRadius: BorderRadius.circular(context.design.cardRadius),
        borderColor: Colors.transparent,
        padding: EdgeInsets.zero,
        textAlign: TextAlign.center,
        maxLines: 3,
        loaderColor: context.secondaryInk,
        loaderBackgroundColor: context.ink.withValues(alpha: 0.12),
        disabledColor: Colors.transparent,
        disabledLoaderColor: context.ink.withValues(alpha: 0.26),
        disabledLoaderBackgroundColor: context.ink.withValues(alpha: 0.12),
        textStyle: context.textTheme.bodyLarge!.copyWith(color: context.ink),
        disabledTextStyle: context.textTheme.bodyLarge!.copyWith(
          color: context.ink,
        ),
        borderWidth: 2,
        borderHoverWidth: 1,
        loaderWidth: 24,
        loaderHeight: 24,
        textOverflow: TextOverflow.ellipsis,
        disabledBorderColor: Colors.transparent,
        hoverColor: context.ink.withValues(alpha: 0.06),
        disabledHoverColor: Colors.transparent,
      );

  final BuildContext context;
}
