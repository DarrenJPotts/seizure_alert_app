import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';

import 'base_button_style.dart';

final class PrimaryButtonStyle extends BaseButtonStyle {
  PrimaryButtonStyle({required this.context})
    : super(
        buttonColor: context.theme.primaryColor,
        textColor: context.paper,
        borderRadius: BorderRadius.circular(context.design.cardRadius),
        borderColor: context.theme.primaryColor,
        padding: EdgeInsets.zero,
        textAlign: TextAlign.center,
        maxLines: 3,
        loaderColor: context.paper,
        loaderBackgroundColor: context.theme.primaryColor,
        disabledColor: context.ink.withValues(alpha: 0.38),
        disabledLoaderColor: context.paper,
        disabledLoaderBackgroundColor: context.ink.withValues(alpha: 0.38),
        textStyle: context.textTheme.bodyLarge!.copyWith(color: context.paper),
        disabledTextStyle: context.textTheme.bodyLarge!.copyWith(
          color: context.paper,
        ),
        borderWidth: 1,
        borderHoverWidth: 1,
        loaderWidth: 24,
        loaderHeight: 24,
        textOverflow: TextOverflow.ellipsis,
        disabledBorderColor: context.ink.withValues(alpha: 0.38),
        hoverColor: context.theme.primaryColor,
        disabledHoverColor: context.theme.primaryColor,
      );

  final BuildContext context;
}
