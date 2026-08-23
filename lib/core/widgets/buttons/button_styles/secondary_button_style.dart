import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

import 'base_button_style.dart';

final class SecondaryButtonStyle extends BaseButtonStyle {
  SecondaryButtonStyle({required this.context})
    : super(
        buttonColor: Colors.black.withValues(alpha: 0.06),
        textColor: Colors.black54,
        borderRadius: BorderRadius.circular(Dimensions.eight),
        borderColor: Colors.black.withValues(alpha: 0.06),
        padding: EdgeInsets.zero,
        textAlign: TextAlign.center,
        maxLines: 3,
        loaderColor: Colors.black54,
        loaderBackgroundColor: Colors.black.withValues(alpha: 0.06),
        disabledColor: Colors.black.withValues(alpha: 0.06),
        disabledLoaderColor: Colors.black54,
        disabledLoaderBackgroundColor: Colors.black.withValues(alpha: 0.06),
        textStyle: context.textTheme.bodyLarge!.copyWith(color: Colors.black),
        disabledTextStyle: context.textTheme.bodyLarge!.copyWith(
          color: Colors.black,
        ),
        borderWidth: 1,
        borderHoverWidth: 1,
        loaderWidth: 24,
        loaderHeight: 24,
        textOverflow: TextOverflow.ellipsis,
        disabledBorderColor: Colors.black.withValues(alpha: 0.06),
        hoverColor: Colors.black.withValues(alpha: 0.08),
        disabledHoverColor: Colors.black.withValues(alpha: 0.06),
      );

  final BuildContext context;
}
