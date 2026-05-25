import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

import 'base_button_style.dart';

final class SecondaryButtonStyle extends BaseButtonStyle {
  SecondaryButtonStyle({required this.context})
    : super(
        buttonColor: Colors.grey.shade200,
        textColor: Colors.black54,
        borderRadius: BorderRadius.circular(Dimensions.eight),
        borderColor: Colors.grey.shade200,
        padding: EdgeInsets.zero,
        textAlign: TextAlign.center,
        maxLines: 3,
        loaderColor: Colors.black54,
        loaderBackgroundColor: Colors.grey.shade200,
        disabledColor: Colors.grey.shade200,
        disabledLoaderColor: Colors.grey,
        disabledLoaderBackgroundColor: Colors.grey,
        textStyle: context.textTheme.bodyLarge!.copyWith(color: Colors.black),
        disabledTextStyle: context.textTheme.bodyLarge!.copyWith(
          color: Colors.black,
        ),
        borderWidth: 1,
        borderHoverWidth: 1,
        loaderWidth: 24,
        loaderHeight: 24,
        textOverflow: TextOverflow.ellipsis,
        disabledBorderColor: Colors.grey,
        hoverColor: Colors.grey.shade200,
        disabledHoverColor: Colors.grey.shade200,
      );

  final BuildContext context;
}
