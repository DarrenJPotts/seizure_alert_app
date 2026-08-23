import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

import 'base_button_style.dart';

final class PrimaryButtonStyle extends BaseButtonStyle {
  PrimaryButtonStyle({required this.context})
    : super(
        buttonColor: context.theme.primaryColor,
        textColor: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.eight),
        borderColor:context.theme.primaryColor,
        padding: EdgeInsets.zero,
        textAlign: TextAlign.center,
        maxLines: 3,
        loaderColor: Colors.white,
        loaderBackgroundColor: context.theme.primaryColor,
        disabledColor: Colors.black38,
        disabledLoaderColor: Colors.white,
        disabledLoaderBackgroundColor: Colors.black38,
        textStyle: context.textTheme.bodyLarge!.copyWith(color: Colors.white),
        disabledTextStyle: context.textTheme.bodyLarge!.copyWith(
          color: Colors.white,
        ),
        borderWidth: 1,
        borderHoverWidth: 1,
        loaderWidth: 24,
        loaderHeight: 24,
        textOverflow: TextOverflow.ellipsis,
        disabledBorderColor: Colors.black38,
        hoverColor: context.theme.primaryColor,
        disabledHoverColor: context.theme.primaryColor,
      );

  final BuildContext context;
}
