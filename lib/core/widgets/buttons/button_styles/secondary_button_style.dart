import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';

import 'base_button_style.dart';

final class SecondaryButtonStyle extends BaseButtonStyle {
  SecondaryButtonStyle({required this.context})
    : super(
        buttonColor: context.ink.withValues(alpha: 0.06),
        textColor: context.secondaryInk,
        borderRadius: BorderRadius.circular(context.design.cardRadius),
        borderColor: context.ink.withValues(alpha: 0.06),
        padding: EdgeInsets.zero,
        textAlign: TextAlign.center,
        maxLines: 3,
        loaderColor: context.secondaryInk,
        loaderBackgroundColor: context.ink.withValues(alpha: 0.06),
        disabledColor: context.ink.withValues(alpha: 0.06),
        disabledLoaderColor: context.secondaryInk,
        disabledLoaderBackgroundColor: context.ink.withValues(alpha: 0.06),
        textStyle: context.textTheme.bodyLarge!.copyWith(color: context.ink),
        disabledTextStyle: context.textTheme.bodyLarge!.copyWith(
          color: context.ink,
        ),
        borderWidth: 1,
        borderHoverWidth: 1,
        loaderWidth: 24,
        loaderHeight: 24,
        textOverflow: TextOverflow.ellipsis,
        disabledBorderColor: context.ink.withValues(alpha: 0.06),
        hoverColor: context.ink.withValues(alpha: 0.08),
        disabledHoverColor: context.ink.withValues(alpha: 0.06),
      );

  final BuildContext context;
}
