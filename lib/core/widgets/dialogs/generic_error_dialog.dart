import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/widgets/buttons/app_button.dart';
import 'package:seizure_app/core/widgets/buttons/button_styles/base_button_style.dart';

class GenericErrorDialog extends StatelessWidget {
  const GenericErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.primaryCallback,
    this.closeCallback,
  });

  final String title;
  final String message;
  final VoidCallback? primaryCallback;
  final VoidCallback? closeCallback;

  static Future<void> show({
    required BuildContext context,
    String? message,
    String title = 'Oops',
    VoidCallback? primaryCallback,
    VoidCallback? closeCallback,
    bool showCloseButton = true,
    bool barrierDismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => GenericErrorDialog(title: title, message: message ?? "Something went wrong"),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.sixteen)),
    title: Row(
      children: [
        Expanded(
          child: Center(
            child: Text(title, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ),
    content: Text(message, style: context.textTheme.bodyMedium, textAlign: .center),
    actions: [
      AppButton(
        onTap: () {
          // context.pop();
          primaryCallback?.call();
        },
        buttonStyle: BaseButtonStyle.primaryButton(context: context),
        buttonText: 'Okay',
      ),
    ],
  );
}
