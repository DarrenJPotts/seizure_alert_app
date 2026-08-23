import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

import 'base_button_style.dart';

final class SecondaryOutlineButtonStyle extends BaseButtonStyle {
  SecondaryOutlineButtonStyle({required this.context})
    : super(
        buttonColor: Colors.transparent,
        textColor: Colors.black54,
        borderRadius: BorderRadius.circular(Dimensions.eight),
        borderColor: context.theme.primaryColor,
        padding: EdgeInsets.zero,
        textAlign: TextAlign.center,
        maxLines: 3,
        loaderColor: Colors.black54,
        loaderBackgroundColor: Colors.black12,
        disabledColor: Colors.transparent,
        disabledLoaderColor: Colors.black26,
        disabledLoaderBackgroundColor: Colors.black12,
        textStyle: context.textTheme.bodyLarge!.copyWith(color: Colors.black),
        disabledTextStyle: context.textTheme.bodyLarge!.copyWith(
          color: Colors.black,
        ),
        borderWidth: 2,
        borderHoverWidth: 1,
        loaderWidth: 24,
        loaderHeight: 24,
        textOverflow: TextOverflow.ellipsis,
        disabledBorderColor: Colors.black26,
        hoverColor: Colors.black.withValues(alpha: 0.06),
        disabledHoverColor: Colors.transparent,
      );

  final BuildContext context;
}
